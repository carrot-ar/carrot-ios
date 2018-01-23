//
//  DriverState.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 1/15/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import Foundation

public protocol DriverState {
  static var `default`: Self { get }
  
  var token: SessionToken? { get }
  var isAuthenticated: Bool { get }
}

public typealias SessionToken = UUID
