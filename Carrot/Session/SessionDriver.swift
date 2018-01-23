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
  
  func start(updateState: @escaping (State) -> Void)
  func end(updateState: @escaping (State) -> Void)
  func socketDidOpen(updateState: @escaping (State) -> Void)
  func socketDidClose(updateState: @escaping (State) -> Void)
  func socketDidFail(with error: Error?, state: State, updateState: @escaping (State) -> Void)

  func updateState(
    from state: State,
    with updateState: @escaping (State) -> Void)
  
  /// Handle receiving any incoming data from the WebSocket that arrives while in an unauthenticated state.
  func didReceive(
    data: Data,
    in state: State,
    updateState: @escaping (State) -> Void)
}
