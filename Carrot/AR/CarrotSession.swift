//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

public final class CarrotSession: SocketDelegate {
  
  // MARK: Lifecycle
  
  init(socket: Socket, messageHandler: @escaping (Result<Message>) -> Void) {
    self.socket = socket
    self.messageHandler = messageHandler
  }
  
  // MARK: Public
  
  public var messageHandler: (Result<Message>) -> Void
  
  private(set) public var state: CarrotSessionState = .closed {
    didSet { handleStateChange() }
  }
  
  public var token: SessionToken? {
    return state.token
  }
  
  func start() {
    socket.eventDelegate = self
    state = .opening
  }
  
  func end() {
    state = .closed
  }
  
  func send(message: Message) throws {
    
  }
  
  // MARK: Private
  
  private var socket: Socket
  private let locationRequester = LocationRequester()
  
  private func handleStateChange() {
    switch state {
    case .opening:
      state = .pendingToken
      socket.open()
    case .closed:
      state = .closed
      socket.close()
    case let .receivedToken(token):
      state = .fetchingLocation(token)
      locationRequester.fetch() { [weak self] result in
        switch result {
        case let .success(location):
          self?.state = .didFetchLocation(token, location)
        case let .error(error):
          self?.state = .failed(self?.state, error)
        }
      }
    case let .didFetchLocation(token, location):
      do {
        let data = try location.data()
        try socket.send(data: data)
        state = .authenticated(token, location)
      } catch {
        state = .failed(state, error)
      }
    case let .failed(previous, error):
      //FIXME: handle error here and attempt to recover based on previous state?
      break
    case .pendingToken, .fetchingLocation, .authenticated:
      break
    }
  }
  
  // MARK: SocketDelegate
  
  public func socketDidOpen() {
  
  }
  
  public func socketDidClose() {
  
  }
  
  public func socketDidReceive(data: Data) {
    switch state {
    case .pendingToken:
      if let token = String(data: data, encoding: .utf8) {
        state = .receivedToken(token)
      }
    case .authenticated:
      do {
        let message = try Message(data: data)
        messageHandler(.success(message))
      } catch {
        messageHandler(.error(error))
      }
    case .closed, .opening, .receivedToken, .fetchingLocation, .didFetchLocation, .failed:
      break
    }
  }
}

public enum CarrotSessionState {
  case closed
  case opening
  case pendingToken
  case receivedToken(SessionToken)
  case fetchingLocation(SessionToken)
  case didFetchLocation(SessionToken, CLLocation)
  case authenticated(SessionToken, CLLocation)
  indirect case failed(CarrotSessionState?, Error)
  
  var token: SessionToken? {
    switch self {
    case .closed, .opening, .pendingToken:
      return nil
    case let .receivedToken(token):
      return token
    case let .fetchingLocation(token):
      return token
    case let .didFetchLocation(token, _):
      return token
    case let .authenticated(token, _):
      return token
    case let .failed(state, _):
      return state?.token ?? nil
    }
  }
}

public typealias SessionToken = String
