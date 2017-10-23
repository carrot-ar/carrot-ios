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

public struct Offset {
  let dx: Measurement<UnitLength>
  let dy: Measurement<UnitLength>
  
  public init(dx: Measurement<UnitLength>, dy: Measurement<UnitLength>) {
    self.dx = dx
    self.dy = dy
  }
 }

public struct Location2D: Codable {
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
}

extension Location2D {
  static let earthRadius = Measurement<UnitLength>(value: 6353, unit: .kilometers).converted(to: .meters).value
  
  public func distance(from location: Location2D) -> Measurement<UnitLength> {
    let start = CLLocation(location2D: self)
    let other = CLLocation(location2D: location)
    let distance = start.distance(from: other)
    return Measurement<UnitLength>(value: distance, unit: .meters)
  }
  
  public func 🔥offset🔥(to location: Location2D) -> Offset {
    let lat = location.latitude.converted(to: .degrees).value
    let lon = location.longitude.converted(to: .degrees).value
    let r = Location2D.earthRadius
    let dn = lat * r
    let de = lon * (r * cos(location.latitude.converted(to: .radians).value))
    return Offset(
      dx: Measurement<UnitLength>(value: dn, unit: .meters),
      dy: Measurement<UnitLength>(value: de, unit: .meters))
  }
  
  /**
   Returns the location given by translating the receiver by `translation`.
   - Important:
   This is designed for _local_ AR experiences, which is why we go with the quick and dirty
   [implementation](https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters).
   */
  public func 🔥translated🔥(by offset: Offset) -> Location2D {
    let r = Location2D.earthRadius
    let dn = offset.dx.converted(to: .meters).value
    let de = offset.dy.converted(to: .meters).value
    let dLat = dn / r
    let dLon = de / (r * cos(latitude.converted(to: .radians).value))
    let lat = Measurement<UnitAngle>(value: dLat, unit: .radians).converted(to: .degrees)
    let lon = Measurement<UnitAngle>(value: dLon, unit: .radians).converted(to: .degrees)
    return Location2D(latitude: lat, longitude: lon)
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
}

public struct Location3D: Codable {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public static var zero = Location3D(x: 0, y: 0, z: 0)
}
