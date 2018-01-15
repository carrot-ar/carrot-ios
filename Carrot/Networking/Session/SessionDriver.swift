//
//  SessionDriver.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 1/15/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import Foundation

public protocol SessionDriver {
  associatedtype State: DriverState
  
  func start(state: State, updateState: @escaping (State) -> Void)
  func end(state: State, updateState: @escaping (State) -> Void)
  func socketDidOpen(state: State, updateState: @escaping (State) -> Void)
  func socketDidClose(state: State, updateState: @escaping (State) -> Void)
  func socketDidFail(with error: Error?, state: State, updateState: @escaping (State) -> Void)

  func updateState(
    from state: State,
    with updateState: @escaping (State) -> Void)
  
  func didReceive(
    data: Data,
    in state: State,
    updateState: @escaping (State) -> Void)
}

public protocol DriverState {
  static var `default`: Self { get }

  var token: SessionToken? { get }
  var isAuthenticated: Bool { get }
}

public enum MessageResult<T: Codable> {
  case success(Message<T>, Endpoint?)
  case error(Error)
}

public typealias SessionToken = UUID
public typealias Endpoint = String
