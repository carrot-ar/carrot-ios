//
//  Translatable.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

protocol Translatable {
  mutating func translate(with operation: AxisOperation)
}

extension Translatable {
  func translate(with operation: AxisOperation) -> Self {
    var copy = self
    copy.translate(with: operation)
    return copy
  }
  
  mutating func translate(with operations: [AxisOperation]) {
    operations.forEach { translate(with: $0) }
  }
  
  func translating(with operations: [AxisOperation]) -> Self {
    var copy = self
    copy.translate(with: operations)
    return copy
  }
}
