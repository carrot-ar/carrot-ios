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
  
  init(socket: Socket, messageHandler: @escaping (Result<Message<T>>) -> Void) {
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
  
  func start() {
    socket.eventDelegate = self
    state = .opening
  }
  
  func end() {
    state = .closed
  }
  
  func send(message: Message<T>) throws {
    //TODO: We need to get more info here based on our format and convert coordinates if applicable, etc.
    //let data = try message.data()
    //try socket.send(data: data)
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
        state = .pendingLocationConfirmation(token, location)
        let data = try location.data()
        try socket.send(data: data)
      } catch {
        state = .failed(state, error)
      }
    case let .failed(previous, error):
      //FIXME: handle error here and attempt to recover based on previous state?
      // For example, if we failed to fetch a location we can retry.
      break
    case .pendingToken, .fetchingLocation, .pendingLocationConfirmation, .authenticated:
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
      //TODO: actually verify that this is a token
      if let token = String(data: data, encoding: .utf8) {
        state = .receivedToken(token)
      }
    case let .pendingLocationConfirmation(token, location):
      if let message = String(data: data, encoding: .utf8), message.hasPrefix("Authenticated:"), message.contains(token) {
        state = .authenticated(token, location)
      }
    case .authenticated:
      do {
        //TODO: We need to get more info here based on our format and convert coordinates if applicable, etc.
        let message = try JSONDecoder().decode(Message<T>.self, from: data)
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
  case pendingLocationConfirmation(SessionToken, CLLocation)
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
    case let .pendingLocationConfirmation(token, _):
      return token
    case let .authenticated(token, _):
      return token
    case let .failed(state, _):
      return state?.token ?? nil
    }
  }
}

public typealias SessionToken = String
