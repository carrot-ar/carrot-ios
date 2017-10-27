//
//  Location+Converting.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/25/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

extension Location2D {
  static let earthRadius = Measurement<UnitLength>(value: 6353, unit: .kilometers).converted(to: .meters).value
  
  /// Returns the `Offset` from the receiver to `location`.
  func offset(to location: Location2D) -> Offset {
    let dLat = location.latitude - latitude
    let dLon = location.longitude - longitude
    let r = Location2D.earthRadius
    let dn = dLat.converted(to: .radians).value * r
    let de = dLon.converted(to: .radians).value * (r * cos(latitude.converted(to: .radians).value))
    return Offset(
      dx: Measurement<UnitLength>(value: de, unit: .meters),
      dz: Measurement<UnitLength>(value: dn, unit: .meters),
      dAlt: location.altitude - altitude)
  }
  
  /**
   Returns the location given by translating the receiver by `translation`.
   - Important:
   This is designed for _local_ AR experiences, which is why we go with the quick and dirty
   [implementation](https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters).
   */
  func translated(by offset: Offset) -> Location2D {
    let r = Location2D.earthRadius
    let dn = offset.dz.converted(to: .meters).value
    let de = offset.dx.converted(to: .meters).value
    let dLat = dn / r
    let dLon = de / (r * cos(latitude.converted(to: .radians).value))
    let lat = Measurement<UnitAngle>(value: dLat, unit: .radians)
    let lon = Measurement<UnitAngle>(value: dLon, unit: .radians)
    let finalLat = (latitude.converted(to: .radians) + lat).converted(to: .degrees)
    let finalLon = (longitude.converted(to: .radians) + lon).converted(to: .degrees)
    return Location2D(
      latitude: finalLat,
      longitude: finalLon,
      altitude: altitude + offset.dAlt)
  }
  
  func 🔥bearing🔥(to endLocation: Location2D) -> Measurement<UnitAngle> {
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
  
  func distance(from location: Location2D) -> Measurement<UnitLength> {
    let start = CLLocation(location2D: self)
    let other = CLLocation(location2D: location)
    let distance = start.distance(from: other)
    return Measurement<UnitLength>(value: distance, unit: .meters)
  }
}
