//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

//TODO: client secret?
public final class CarrotSession<T: Codable>: SocketDelegate {
  
  // MARK: Lifecycle
  
  public init(
    socket: Socket,
    locationRequester: LocationRequester = CarrotLocationRequester(),
    messageHandler: @escaping (Result<Message<T>>, String?) -> Void,
    errorHandler: @escaping (CarrotSessionState?, Error) -> ErrorRecoveryCommand?)
  {
    self.socket = socket
    self.locationRequester = locationRequester
    self.messageHandler = messageHandler
    self.errorHandler = errorHandler
  }
  
  // MARK: Public
  
  public let messageHandler: (Result<Message<T>>, String?) -> Void
  public let errorHandler: (CarrotSessionState?, Error) -> ErrorRecoveryCommand?
  
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
    case let .authenticated(token, location):
      let sendable = Sendable.message(token, endpoint, location, message)
      let data = try JSONEncoder().encode(sendable)
      try socket.send(data: data)
    case .closed,
         .closing,
         .opening,
         .pendingToken,
         .receivedToken,
         .fetchingLocation,
         .failed:
      throw CarrotSessionError.notAuthorized
    }
  }
  
  // MARK: Private
  
  private var socket: Socket
  private var locationRequester: LocationRequester
  private var stateDidChange: ((CarrotSessionState) -> Void)?
  
  private func handleStateChange(previous: CarrotSessionState) {
    stateDidChange?(state)
    switch state {
    case .opening:
      socket.open()
    case .closing:
      socket.close()
    case let .receivedToken(token):
      state = .fetchingLocation(token)
      locationRequester.fetch() { [weak self] result in
        switch result {
        case let .success(location):
          self?.state = .authenticated(token, Location2D(from: location))
        case let .error(error):
          self?.state = .failed(on: self?.state, previous: .receivedToken(token), error)
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
    case .closed, .pendingToken, .fetchingLocation,  .authenticated:
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
      if let token = String(data: data, encoding: .utf8) {
        state = .receivedToken(token)
      }
    case let .authenticated(_, origin):
      do {
        let sendable = try JSONDecoder().decode(Sendable<T>.self, from: data)
        switch sendable {
        case let .message(_, endPoint, foreignOrigin, message):
          let receivable = message.localized(from: foreignOrigin, to: origin)
          messageHandler(.success(receivable), endPoint)
        }
      } catch {
        messageHandler(.error(error), nil)
      }
    case .opening, .closing, .closed, .receivedToken, .fetchingLocation, .failed:
      break
    }
  }
}

public enum CarrotSessionState {
  case opening
  case closing
  case closed
  case pendingToken
  case receivedToken(SessionToken)
  case fetchingLocation(SessionToken)
  case authenticated(SessionToken, Location2D)
  indirect case failed(on: CarrotSessionState?, previous: CarrotSessionState?, Error)
  
  var token: SessionToken? {
    switch self {
    case .opening, .closing, .closed, .pendingToken:
      return nil
    case let .receivedToken(token):
      return token
    case let .fetchingLocation(token):
      return token
    case let .authenticated(token, _):
      return token
    case let .failed(state, _, _):
      return state?.token ?? nil
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

public typealias SessionToken = String
