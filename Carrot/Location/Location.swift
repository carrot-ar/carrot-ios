//
//  Location.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//
//  🔥 = need to test!!

import Foundation
import CoreLocation

public struct Offset: Equatable {
  public let dx: Measurement<UnitLength>
  public let dz: Measurement<UnitLength>
  public let dAlt: Measurement<UnitLength>
  
  public init(
    dx: Measurement<UnitLength>,
    dz: Measurement<UnitLength>,
    dAlt: Measurement<UnitLength>)
  {
    self.dx = dx
    self.dz = dz
    self.dAlt = dAlt
  }
  
  public static func ==(lhs: Offset, rhs: Offset) -> Bool {
    return lhs.dx == rhs.dx &&
           lhs.dz == rhs.dz &&
           lhs.dAlt == rhs.dAlt
  }
 }

public struct Location2D {
  public var latitude: Measurement<UnitAngle>
  public var longitude: Measurement<UnitAngle>
  public var altitude: Measurement<UnitLength>
  
  public init(latitude: Measurement<UnitAngle>, longitude: Measurement<UnitAngle>, altitude: Measurement<UnitLength>) {
    self.latitude = latitude
    self.longitude = longitude
    self.altitude = altitude
  }
  
  public init(from location: CLLocation) {
    self.latitude = Measurement<UnitAngle>(value: location.coordinate.latitude, unit: .degrees)
    self.longitude = Measurement<UnitAngle>(value: location.coordinate.longitude, unit: .degrees)
    self.altitude = Measurement<UnitLength>(value: location.altitude, unit: .meters)
  }
}

extension Location2D: Codable, Equatable {
  enum CodingKeys: String, CodingKey {
    case latitude
    case longitude
    case altitude
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let lat = try values.decode(Double.self, forKey: .latitude)
    latitude = Measurement<UnitAngle>(value: lat, unit: .degrees)
    let lon = try values.decode(Double.self, forKey: .longitude)
    longitude = Measurement<UnitAngle>(value: lon, unit: .degrees)
    let alt = try values.decode(Double.self, forKey: .altitude)
    altitude = Measurement<UnitLength>(value: alt, unit: .meters)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(latitude.converted(to: .degrees).value, forKey: .latitude)
    try container.encode(longitude.converted(to: .degrees).value, forKey: .longitude)
    try container.encode(altitude.converted(to: .meters).value, forKey: .altitude)
  }
  
  public static func ==(lhs: Location2D, rhs: Location2D) -> Bool {
    return lhs.latitude == rhs.latitude &&
           lhs.longitude == rhs.longitude &&
           lhs.altitude == rhs.altitude
  }
}

public struct Location3D {
  public var x: Double
  public var z: Double
  public var altitude: Double
  
  public init(x: Double, z: Double, altitude: Double) {
    self.x = x
    self.z = z
    self.altitude = altitude
  }
}

extension Location3D: Codable, Equatable {
  enum CodingKeys: String, CodingKey {
    case x
    case z
    case altitude = "y"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    x = try values.decode(Double.self, forKey: .x)
    z = try values.decode(Double.self, forKey: .z)
    altitude = try values.decode(Double.self, forKey: .altitude)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(x, forKey: .x)
    try container.encode(z, forKey: .z)
    try container.encode(altitude, forKey: .altitude)
  }
  
  public static func ==(lhs: Location3D, rhs: Location3D) -> Bool {
    return lhs.x == rhs.x &&
           lhs.z == rhs.z &&
           lhs.altitude == rhs.altitude
  }
}
