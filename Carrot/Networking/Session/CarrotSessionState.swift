//
//  CarrotSessionState.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import CoreLocation
import Foundation
import Parrot

public enum CarrotSessionState {
  case opening
  case closing
  case closed
  case pendingToken
  case receivedInitialMessage(SessionToken, BeaconInfo)
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

