//
//  Location.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

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
