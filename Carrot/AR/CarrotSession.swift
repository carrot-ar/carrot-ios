//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

//TODO: client secret somewhere here eventually?
public final class CarrotSession<T: Codable>: SocketDelegate {
  
  // MARK: Lifecycle
  
  public init(socket: Socket, messageHandler: @escaping (Result<Message<T>>) -> Void) {
    self.socket = socket
    self.messageHandler = messageHandler
  }
  
  // MARK: Public
  
  public var messageHandler: (Result<Message<T>>) -> Void
  
  private(set) public var state: CarrotSessionState = .closed {
    didSet { handleStateChange() }
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
    state = .closed
  }
  
  public func send(message: Message<T>, to endpoint: String) throws {
    switch state {
    case let .authenticated(token, location):
      let sendable = Sendable.message(token, endpoint, location, message)
      let data = try JSONEncoder().encode(sendable)
      try socket.send(data: data)
    case .closed,
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
  private var stateDidChange: ((CarrotSessionState) -> Void)?
  
  private func handleStateChange() {
    stateDidChange?(state)
    switch state {
    case .opening:
      state = .pendingToken
      socket.open()
    case .closed:
      socket.close()
    case let .receivedToken(token):
      let locationRequester = LocationRequester()
      locationRequester.fetch() { [weak self] result in
        switch result {
        case let .success(location):
          self?.state = .authenticated(token, Location2D(from: location))
        case let .error(error):
          self?.state = .failed(self?.state, error)
        }
      }
      state = .fetchingLocation(token, locationRequester)
    case let .failed(previous, error):
      //FIXME: handle error here and attempt to recover based on previous state?
      // For example, if we failed to fetch a location we can retry.
      break
    case .pendingToken, .fetchingLocation,  .authenticated:
      break
    }
  }
  
  // MARK: SocketDelegate
  
  public func socketDidOpen() {
    // NOOP for now
    
  }
  
  public func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?) {
    // NOOP for now
  }
  
  public func socketDidFail(with error: Error?) {
    // NOOP for now
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
        case let .message(_, _, foreignOrigin, message):
          var receivable = message
          receivable.location = .zero //FIXME: convert via `origin`, `foreignOrigin`, and `receivable.location`
          messageHandler(.success(receivable))
        }
      } catch {
        messageHandler(.error(error))
      }
    case .closed, .opening, .receivedToken, .fetchingLocation, .failed:
      break
    }
  }
}

public enum CarrotSessionState {
  case closed
  case opening
  case pendingToken
  case receivedToken(SessionToken)
  case fetchingLocation(SessionToken, LocationRequester)
  case authenticated(SessionToken, Location2D)
  indirect case failed(CarrotSessionState?, Error)
  
  var token: SessionToken? {
    switch self {
    case .closed, .opening, .pendingToken:
      return nil
    case let .receivedToken(token):
      return token
    case let .fetchingLocation(token, _):
      return token
    case let .authenticated(token, _):
      return token
    case let .failed(state, _):
      return state?.token ?? nil
    }
  }
}

public enum CarrotSessionError: Error {
  case notAuthorized
}

public typealias SessionToken = String
