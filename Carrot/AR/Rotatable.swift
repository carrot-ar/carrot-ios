//
//  Rotatable.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

protocol Rotatable {
  mutating func rotate(with operation: AxisOperation)
}

extension Rotatable {
  func rotate(with operation: AxisOperation) -> Self {
    var copy = self
    copy.rotate(with: operation)
    return copy
  }
  
  mutating func rotate(with operations: [AxisOperation]) {
    operations.forEach { rotate(with: $0) }
  }
  
  func rotating(with operations: [AxisOperation]) -> Self {
    var copy = self
    copy.rotate(with: operations)
    return copy
  }
}
