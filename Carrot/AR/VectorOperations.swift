//
//  VectorOperations.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import simd

extension float3: Translatable {
  mutating func translate(with operation: AxisOperation) {
    switch operation {
    case let .by(factor, along: axis):
      switch axis {
      case .x:
        x += factor
      case .y:
        y += factor
      case .z:
        z += factor
      }
    }
  }
}
