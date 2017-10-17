//
//  Location.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

public struct Location2D: Codable {
  public var latitude: Double
  public var longitude: Double
  
  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }
  
  public init(from location: CLLocation) {
    self.latitude = location.coordinate.latitude
    self.longitude = location.coordinate.longitude
  }
  
  public static var zero = Location2D(latitude: 0, longitude: 0)
}

public struct Location3D: Codable {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public static var zero = Location3D(x: 0, y: 0, z: 0)
}
