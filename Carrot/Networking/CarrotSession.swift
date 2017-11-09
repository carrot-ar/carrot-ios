//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

import Parrot
import simd

//TODO: client secret?
public final class CarrotSession<T: Codable>: SocketDelegate {
  
  // MARK: Lifecycle
  
  public init(
    socket: Socket,
    currentTransform: @escaping () -> matrix_float4x4,
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
      let sendable = Sendable.message(token, endpoint, message)
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
  private let currentTransform: () -> matrix_float4x4
  private let messageHandler: (Result<Message<T>>, String?) -> Void
  private let errorHandler: (CarrotSessionState?, Error) -> ErrorRecoveryCommand?
  
  private let beaconIdentifier = "com.Carrot.PrimaryBeacon"
  private var stateDidChange: ((CarrotSessionState) -> Void)?
  
  private func handleStateChange(previous: CarrotSessionState) {
    stateDidChange?(state)
    switch state {
    case .opening:
      socket.open()
    case .closing:
      socket.close()
    case let .receivedInitialMessage(token, beaconInfo):
      if let info = beaconInfo {
        let monitor = BeaconMonitor(
          uuid: info.uuid,
          identifier: info.identifier,
          params: info.params)
        state = .pendingImmediatePing(token, monitor, .unknown)
        monitor.startMonitoring(
          onProximityUpdate: { [weak self] _, proximity in
            switch proximity {
            case .immediate:
              if let transform = self?.currentTransform() {
                self?.state = .authenticatedSecondary(token)
                let location = Location3D(transform: transform)
                let message = Message<T>.offset(location)
                let sendable = Sendable<T>.message(token, "carrot.transform", message)
                do {
                  let data = try JSONEncoder().encode(sendable)
                  try self?.socket.send(data: data)
                } catch {
                  self?.state = .failed(on: self?.state, previous: .receivedInitialMessage(token, beaconInfo), error)
                }
              }
            case .near, .far, .unknown:
              self?.state = .pendingImmediatePing(token, monitor, proximity)
            }
          },
          onError: { [weak self] error in
            self?.state = .failed(on: self?.state, previous: .receivedInitialMessage(token, beaconInfo), error)
          }
        )
      } else {
        let advertiser = BeaconAdvertiser(
          uuid: token,
          identifier: beaconIdentifier,
          params: .none)
        state = .pendingAdvertising(token, advertiser, .idle)
        advertiser.startAdvertising { [weak self] advertiser, advertisingState in
          switch advertisingState {
          case .advertising:
            self?.state = .authenticatedPrimary(token, advertiser)
          case .idle, .queued:
            self?.state = .pendingAdvertising(token, advertiser, advertisingState)
          case let .error(error):
            self?.state = .failed(on: self?.state, previous: .receivedInitialMessage(token, beaconInfo), error)
          }
        }
      }
    case let .failed(failedOn, previous, error):
      guard let command = errorHandler(failedOn, error) else { return }
      switch command {
      case .restart:
        state = .opening
      case .retry:
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
  
  // MARK: SocketDelegate
  
  public func socketDidOpen() {
    state = .pendingToken
  }
  
  public func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?) {
    state = .closed
  }
  
  public func socketDidFail(with error: Error?) {
    state = .failed(on: state, previous: nil, error ?? CarrotSessionError.failureWithoutError)
  }
  
  public func socketDidReceive(data: Data) {
    switch state {
    case .pendingToken:
      do {
        let sendable = try JSONDecoder().decode(Sendable<BeaconInfo?>.self, from: data)
        switch sendable {
        case let .message(token, _, message):
          switch message {
          case let .full(_, beacon):
            state = .receivedInitialMessage(token, beacon)
          case let .object(beacon):
            state = .receivedInitialMessage(token, beacon)
          case .offset:
            break
          }
        }
      } catch {
        messageHandler(.error(error), nil)
      }
    case .authenticatedPrimary, .authenticatedSecondary:
      do {
        let sendable = try JSONDecoder().decode(Sendable<T>.self, from: data)
        switch sendable {
        case let .message(_, endpoint, message):
          messageHandler(.success(message), endpoint)
        }
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
}

public enum CarrotSessionState {
  case opening
  case closing
  case closed
  case pendingToken
  case receivedInitialMessage(SessionToken, BeaconInfo?)
  case pendingImmediatePing(SessionToken, BeaconMonitor, CLProximity)
  case pendingAdvertising(SessionToken, BeaconAdvertiser, BeaconAdvertisingState)
  case authenticatedSecondary(SessionToken)
  case authenticatedPrimary(SessionToken, BeaconAdvertiser)
  indirect case failed(on: CarrotSessionState?, previous: CarrotSessionState?, Error)
  
  public var token: SessionToken? {
    switch self {
    case .opening, .closing, .closed, .pendingToken:
      return nil
    case let .receivedInitialMessage(token, _):
      return token
    case let .pendingImmediatePing(token, _, _):
      return token
    case let .authenticatedSecondary(token):
      return token
    case let .pendingAdvertising(token, _, _):
      return token
    case let .authenticatedPrimary(token, _):
      return token
    case let .failed(state, _, _):
      return state?.token ?? nil
    }
  }
  
  public var isAuthenticated: Bool {
    switch self {
    case .authenticatedPrimary, .authenticatedSecondary:
      return true
    case .closed,
         .closing,
         .opening,
         .pendingToken,
         .receivedInitialMessage,
         .pendingImmediatePing,
         .pendingAdvertising,
         .failed:
      return false
    }
  }
}

public enum ErrorRecoveryCommand {
  case restart
  case retry
  case close
}

public enum CarrotSessionError: Error {
  case failureWithoutError
  case notAuthorized
}

public typealias SessionToken = UUID
