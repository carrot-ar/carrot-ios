//
//  Location.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import simd

public struct Location3D : Codable {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }
}

extension Location3D {
  
 init(transform: matrix_float4x4) {
    let position = transform.position
    self.init(
      x: Double(position.x),
      y: Double(position.y),
      z: Double(position.z))
  }
}
