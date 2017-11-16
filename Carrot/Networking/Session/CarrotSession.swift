//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import CoreLocation
import Foundation
import Parrot
import simd

// MARK: - CarrotSession

public final class CarrotSession<T: Codable>: SocketDelegate {
  
  // MARK: Lifecycle
  
  public init(
    socket: Socket,
    currentTransform: @escaping () -> matrix_float4x4?,
    messageHandler: @escaping (Result<Message<T>>, String?) -> Void,
    errorHandler: @escaping (CarrotSessionState?, Error) -> ErrorRecoveryCommand?)
  {
    self.socket = socket
    self.currentTransform = currentTransform
    self.messageHandler = messageHandler
    self.errorHandler = errorHandler
  }
  
  // MARK: Public
  
  private(set) public var state: CarrotSessionState = .closed {
    didSet { handleStateChange(previous: oldValue) }
  }
  
  public var token: SessionToken? {
    return state.token
  }
  
  public func start(stateDidChange: @escaping (CarrotSessionState) -> Void) {
    self.stateDidChange = stateDidChange
    socket.eventDelegate = self
    state = .opening
  }
  
  public func end() {
    state = .closing
  }
  
  public func send(message: Message<T>, to endpoint: String) throws {
    switch state {
    case let .authenticatedPrimary(token, _), let .authenticatedSecondary(token):
      let sendable = Sendable(
        token: token,
        endpoint: endpoint,
        message: message)
      let data = try JSONEncoder().encode(sendable)
      try socket.send(data: data)
    case .closed,
         .closing,
         .opening,
         .pendingToken,
         .receivedInitialMessage,
         .pendingImmediatePing,
         .pendingAdvertising,
         .failed:
      throw CarrotSessionError.notAuthorized
    }
  }
  
  // MARK: Private
  
  private let socket: Socket
  private let currentTransform: () -> matrix_float4x4?
  private let messageHandler: (Result<Message<T>>, String?) -> Void
  private let errorHandler: (CarrotSessionState?, Error) -> ErrorRecoveryCommand?
  private var stateDidChange: ((CarrotSessionState) -> Void)?
  
  private func handleStateChange(previous: CarrotSessionState) {
    stateDidChange?(state)
    switch state {
    case .opening:
      socket.open()
    case .closing:
      socket.close()
    case let .receivedInitialMessage(token, beaconInfo):
      let isPrimaryDevice = (token == beaconInfo.uuid)
      if isPrimaryDevice {
        advertise(with: beaconInfo, token: token) { [weak self] advertiser, advertisingState in
          switch advertisingState {
          case .advertising:
            self?.state = .authenticatedPrimary(token, advertiser)
          case .idle, .queued:
            self?.state = .pendingAdvertising(token, advertiser, advertisingState)
          case let .error(error):
            self?.state = .failed(
              on: self?.state,
              previous: .receivedInitialMessage(token, beaconInfo),
              error)
          }
        }
      } else {
        monitor(
          for: beaconInfo,
          token: token,
          onProximityUpdate: { [weak self] monitor, proximity in
            self?.handleProximityUpdate(
              to: proximity,
              monitor: monitor,
              token: token,
              beaconInfo: beaconInfo)
          },
          onError: { [weak self] error in
            self?.state = .failed(
              on: self?.state,
              previous: .receivedInitialMessage(token, beaconInfo),
              error)
          }
        )
      }
    case let .failed(failedOn, previous, error):
      guard let command = errorHandler(failedOn, error) else { return }
      switch command {
      case .restart:
        state = .opening
      case .retryOrRestart:
        state = previous ?? .opening
      case .retryOrClose:
        state = previous ?? .closed
      case .close:
        state = .closed
      }
    case .closed,
         .pendingToken,
         .pendingImmediatePing,
         .pendingAdvertising,
         .authenticatedSecondary,
         .authenticatedPrimary:
      break
    }
  }
  
  private func advertise(
    with beaconInfo: BeaconInfo,
    token: SessionToken,
    onStateChange: @escaping (BeaconAdvertiser, BeaconAdvertisingState) -> Void)
  {
    let advertiser = BeaconAdvertiser(
      uuid: token,
      identifier: beaconInfo.identifier,
      params: beaconInfo.params)
    state = .pendingAdvertising(token, advertiser, .idle)
    advertiser.startAdvertising(onStateChange: onStateChange)
  }
  
  private func monitor(
    for beaconInfo: BeaconInfo,
    token: SessionToken,
    onProximityUpdate: @escaping (BeaconMonitor, CLProximity) -> Void,
    onError: @escaping (Error) -> Void)
  {
    let monitor = BeaconMonitor(
      uuid: beaconInfo.uuid,
      identifier: beaconInfo.identifier,
      params: beaconInfo.params)
    state = .pendingImmediatePing(token, monitor, .unknown)
    monitor.startMonitoring(
      onProximityUpdate: onProximityUpdate,
      onError: onError)
  }
  
  private func handleProximityUpdate(
    to proximity: CLProximity,
    monitor: BeaconMonitor,
    token: SessionToken,
    beaconInfo: BeaconInfo)
  {
    switch proximity {
    case .immediate:
      state = .authenticatedSecondary(token)
      let sendable = response(for: .transform, token: token)
      do {
        let data = try JSONEncoder().encode(sendable)
        try socket.send(data: data)
      } catch {
        state = .failed(
          on: state,
          previous: .receivedInitialMessage(token, beaconInfo),
          error)
      }
    case .near, .far, .unknown:
      state = .pendingImmediatePing(token, monitor, proximity)
    }
  }
  
  // MARK: SocketDelegate
  
  public func socketDidOpen() {
    state = .pendingToken
  }
  
  public func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?) {
    state = .closed
  }
  
  public func socketDidFail(with error: Error?) {
    state = .failed(
      on: state,
      previous: nil,
      error ?? CarrotSessionError.failureWithoutError)
  }
  
  public func socketDidReceive(data: Data) {
    if let reservedSendable = try? JSONDecoder().decode(ReservedSendable.self, from: data),
      let token = state.token,
      let sendableResponse = response(for: reservedSendable.endpoint, token: token)
    {
      do {
        let data = try JSONEncoder().encode(sendableResponse)
        try socket.send(data: data)
      } catch {
        state = .failed(
          on: state,
          previous: nil,
          error)
      }
      return
    }
    switch state {
    case .pendingToken:
      do {
        let reservedSendable = try JSONDecoder().decode(ReservedSendable.self, from: data)
        switch reservedSendable.message {
        case let .beacon(beaconInfo):
          state = .receivedInitialMessage(reservedSendable.token, beaconInfo)
        case .transform, .none:
          break
        }
      } catch {
        assert(false, "[ERROR]: \(error)")
      }
    case .authenticatedPrimary, .authenticatedSecondary:
      do {
        let sendable = try JSONDecoder().decode(Sendable<T>.self, from: data)
        messageHandler(.success(sendable.message), sendable.endpoint)
      } catch {
        messageHandler(.error(error), nil)
      }
    case .opening,
         .closing,
         .closed,
         .receivedInitialMessage,
         .pendingImmediatePing,
         .pendingAdvertising,
         .failed:
      break
    }
  }
  
  private func response(for endpoint: ReservedEndpoint, token: SessionToken) -> ReservedSendable? {
    switch endpoint {
    case .transform:
      guard let transform = currentTransform() else { return nil }
      let location = Location3D(transform: transform)
      let message = ReservedMessage.transform(location)
      return ReservedSendable(
        token: token,
        message: message)
    case .beacon:
      return nil
    }
  }
}

// MARK: - ErrorRecoveryCommand

public enum ErrorRecoveryCommand {
  case restart
  case retryOrRestart
  case retryOrClose
  case close
}

// MARK: - CarrotSessionError

public enum CarrotSessionError: Error {
  case failureWithoutError
  case notAuthorized
}

// MARK: - SessionToken

public typealias SessionToken = UUID
