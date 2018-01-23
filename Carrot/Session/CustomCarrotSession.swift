//
//  CustomCarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import CoreLocation
import Foundation
import simd

// MARK: - CustomCarrotSession

public class CustomCarrotSession<Driver: SessionDriver, Object: Codable>: SocketDelegate {
  
  // MARK: Lifecycle
  
  public init(
    socket: Socket,
    driver: Driver,
    messageHandler: @escaping (MessageResult<Object>) -> Void,
    errorHandler: @escaping (Driver.State?, Error) -> Void)
  {
    self.socket = socket
    self.driver = driver
    self.messageHandler = messageHandler
    self.errorHandler = errorHandler
  }
  
  // MARK: Public
  
  private(set) public var state: Driver.State = .default {
    didSet { handleStateChange() }
  }
  
  public var token: SessionToken? {
    return state.token
  }
  
  public func start(stateDidChange: @escaping (Driver.State) -> Void) {
    self.stateDidChange = stateDidChange
    socket.eventDelegate = self
    driver.start { [weak self] newState in
      self?.state = newState
    }
  }
  
  public func end() {
    driver.end { [weak self] newState in
      self?.state = newState
    }
  }
  
  public func send(message: Message<Object>, to endpoint: Endpoint) throws {
    guard state.isAuthenticated, let token = state.token else {
      throw CarrotSessionError.notAuthenticated
    }
    let sendable = Sendable(
      token: token,
      endpoint: endpoint,
      message: message)
    let data = try JSONEncoder().encode(sendable)
    try socket.send(data: data)
  }
  
  // MARK: Private
  
  private let socket: Socket
  private let driver: Driver
  private let messageHandler: (MessageResult<Object>) -> Void
  private let errorHandler: (Driver.State, Error) -> Void
  private var stateDidChange: ((Driver.State) -> Void)?
  
  private func handleStateChange() {
    stateDidChange?(state)
    driver.updateState(from: state) { [weak self] newState in
      self?.state = newState
    }
  }
  
  // MARK: SocketDelegate
  
  public func socketDidOpen() {
    driver.socketDidOpen { [weak self] newState in
      self?.state = newState
    }
  }
  
  public func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?) {
    driver.socketDidClose  { [weak self] newState in
      self?.state = newState
    }
  }
  
  public func socketDidFail(with error: Error?) {
    driver.socketDidFail(with: error, state: state) { [weak self] newState in
      self?.state = newState
    }
  }
  
  public func socketDidReceive(data: Data) {
    if state.isAuthenticated {
      do {
        let sendable = try JSONDecoder().decode(Sendable<Object>.self, from: data)
        messageHandler(.success(sendable.message, sendable.endpoint))
      } catch {
        messageHandler(.error(error))
      }
    } else {
      driver.didReceive(data: data, in: state) { [weak self] newState in
        self?.state = newState
      }
    }
  }
}

// MARK: - CarrotSessionError

public enum CarrotSessionError: Error {
  case notAuthenticated
}

// MARK: - Typealiases

public typealias Endpoint = String
