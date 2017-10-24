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
  public let dy: Measurement<UnitLength>
  
  public init(dx: Measurement<UnitLength>, dy: Measurement<UnitLength>) {
    self.dx = dx
    self.dy = dy
  }
  
  public static func ==(lhs: Offset, rhs: Offset) -> Bool {
    return lhs.dx == rhs.dx &&
           lhs.dy == rhs.dy
  }
 }

public struct Location2D: Codable, Equatable {
  public var latitude: Measurement<UnitAngle>
  public var longitude: Measurement<UnitAngle>
  
  public init(latitude: Measurement<UnitAngle>, longitude: Measurement<UnitAngle>) {
    self.latitude = latitude
    self.longitude = longitude
  }
  
  public init(from location: CLLocation) {
    self.latitude = Measurement<UnitAngle>(value: location.coordinate.latitude, unit: .degrees)
    self.longitude = Measurement<UnitAngle>(value: location.coordinate.longitude, unit: .degrees)
  }
  
  public static func ==(lhs: Location2D, rhs: Location2D) -> Bool {
    return lhs.latitude == rhs.latitude &&
           lhs.longitude == rhs.longitude
  }
}

extension Location2D {
  static let earthRadius = Measurement<UnitLength>(value: 6353, unit: .kilometers).converted(to: .meters).value
  
  public func 🔥offset🔥(to location: Location2D) -> Offset {
    let dLat = location.latitude - latitude
    let dLon = location.longitude - longitude
    let r = Location2D.earthRadius
    let dn = dLat.converted(to: .radians).value * r
    let de = dLon.converted(to: .radians).value * (r * cos(latitude.converted(to: .radians).value))
    return Offset(
      dx: Measurement<UnitLength>(value: de, unit: .meters),
      dy: Measurement<UnitLength>(value: dn, unit: .meters))
  }
  
  /**
   Returns the location given by translating the receiver by `translation`.
   - Important:
   This is designed for _local_ AR experiences, which is why we go with the quick and dirty
   [implementation](https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters).
   */
  public func 🔥translated🔥(by offset: Offset) -> Location2D {
    let r = Location2D.earthRadius
    let dn = offset.dy.converted(to: .meters).value
    let de = offset.dx.converted(to: .meters).value
    let dLat = dn / r
    let dLon = de / (r * cos(latitude.converted(to: .radians).value))
    let lat = Measurement<UnitAngle>(value: dLat, unit: .radians)
    let lon = Measurement<UnitAngle>(value: dLon, unit: .radians)
    let finalLat = (latitude.converted(to: .radians) + lat).converted(to: .degrees)
    let finalLon = (longitude.converted(to: .radians) + lon).converted(to: .degrees)
    return Location2D(latitude: finalLat, longitude: finalLon)
  }
  
  public func 🔥bearing🔥(to endLocation: Location2D) -> Measurement<UnitAngle> {
    let lat1 = latitude.converted(to: .radians).value
    let lon1 = longitude.converted(to: .radians).value
    let lat2 = endLocation.latitude.converted(to: .radians).value
    let lon2 = endLocation.longitude.converted(to: .radians).value
    let dLon = lon2 - lon1
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    var azimuth = Measurement<UnitAngle>(value: radiansBearing, unit: .radians).converted(to: .degrees)
    if (azimuth.value < 0) { azimuth.value += 360 }
    return azimuth
  }
  
  public func distance(from location: Location2D) -> Measurement<UnitLength> {
    let start = CLLocation(location2D: self)
    let other = CLLocation(location2D: location)
    let distance = start.distance(from: other)
    return Measurement<UnitLength>(value: distance, unit: .meters)
  }
}

public struct Location3D: Codable, Equatable {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public static func ==(lhs: Location3D, rhs: Location3D) -> Bool {
    return lhs.x == rhs.x &&
           lhs.y == rhs.y &&
           lhs.z == rhs.z
  }
}
