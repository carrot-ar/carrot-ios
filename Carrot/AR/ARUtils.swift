//
//  ARUtils.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

enum AxisOperation {
  case by(Float, along: Axis)
}

extension AxisOperation {
  mutating func negate() {
    switch self {
    case let .by(factor, along: axis):
      self = .by(-factor, along: axis)
    }
  }
  
  func negated() -> AxisOperation {
    var copy = self
    copy.negate()
    return copy
  }
}

enum Axis {
  case x
  case y
  case z
}
