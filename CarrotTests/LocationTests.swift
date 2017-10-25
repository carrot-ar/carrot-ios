//
//  LocationTests.swift
//  CarrotTests
//
//  Created by Gonzalo Nunez on 10/24/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import XCTest
import Carrot

class LocationTests: XCTestCase {
  
  static let angleDelta = Measurement<UnitAngle>(value: 0.004, unit: .degrees)
  static let distanceDelta = Measurement<UnitLength>(value: 0.001, unit: .meters)

  func testSameLocation() {
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let zeroOffset = Offset(dx: zero, dz: zero, dAlt: zero)
    let latLon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let location = Location2D(latitude: latLon, longitude: latLon, altitude: zero)
    let offset = location.🔥offset🔥(to: location)
    assert(offset == zeroOffset)
  }
  
  func testZeroOffset() {
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let latLon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let location = Location2D(latitude: latLon, longitude: latLon, altitude: zero)
    let zeroOffset = Offset(dx: zero, dz: zero, dAlt: zero)
    let offsetted = location.🔥translated🔥(by: zeroOffset)
    assert(offsetted == location)
  }
  
  func testCloseOffset() {
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let lat = Measurement<UnitAngle>(value: 51, unit: .degrees)
    let lon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let start = Location2D(latitude: lat, longitude: lon, altitude: zero)
    let dim = Measurement<UnitLength>(value: 100, unit: .meters)
    let offset = Offset(dx: dim, dz: dim, dAlt: zero)
    let actual = start.🔥translated🔥(by: offset)
    let expectedLat = Measurement<UnitAngle>(value: 51.0009018699827, unit: .degrees)
    let expectedLon = Measurement<UnitAngle>(value: 0.00143308502480555, unit: .degrees)
    let expected = Location2D(latitude: expectedLat, longitude: expectedLon, altitude: zero)
    assert(locationAccurate(expected: expected, actual: actual))
  }
  
  func testExpectedOffset() {
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let lat = Measurement<UnitAngle>(value: 51, unit: .degrees)
    let lon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let start = Location2D(latitude: lat, longitude: lon, altitude: zero)
    let endLat = Measurement<UnitAngle>(value: 51.0009018699827, unit: .degrees)
    let endLon = Measurement<UnitAngle>(value: 0.00143308502480555, unit: .degrees)
    let end = Location2D(latitude: endLat, longitude: endLon, altitude: zero)
    let actual = start.🔥offset🔥(to: end)
    let dim = Measurement<UnitLength>(value: 100, unit: .meters)
    let expected = Offset(dx: dim, dz: dim, dAlt: zero)
    assert(offsetAccurate(expected: expected, actual: actual))
  }
  
  func testAltitudeChange() {
    let zeroDegrees = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let tenMeters = Measurement<UnitLength>(value: 10, unit: .meters)
    let start = Location2D(latitude: zeroDegrees, longitude: zeroDegrees, altitude: tenMeters)
    let twentyMeters = Measurement<UnitLength>(value: 20, unit: .meters)
    let end = Location2D(latitude: zeroDegrees, longitude: zeroDegrees, altitude: twentyMeters)
    let actual = start.🔥offset🔥(to: end)
    let zeroMeters = Measurement<UnitLength>(value: 0, unit: .meters)
    let expected = Offset(dx: zeroMeters, dz: zeroMeters, dAlt: tenMeters)
    assert(offsetAccurate(expected: expected, actual: actual))
  }
  
  func testToAndFromOffset() {
    
  }
  
  // MARK: - Helpers
  
  private func locationAccurate(
    to delta: Measurement<UnitAngle> = LocationTests.angleDelta,
    expected: Location2D,
    actual: Location2D) -> Bool
  {
    let latRange = (expected.latitude - delta)...(expected.latitude + delta)
    let lonRange = (expected.longitude - delta)...(expected.longitude + delta)
    let altRange = (expected.altitude - LocationTests.distanceDelta)...(expected.altitude + LocationTests.distanceDelta)
    return latRange ~= actual.latitude &&
           lonRange ~= actual.longitude &&
           altRange ~= actual.altitude
  }
  
  private func offsetAccurate(
    to delta: Measurement<UnitLength> = LocationTests.distanceDelta,
    expected: Offset,
    actual: Offset) -> Bool
  {
    let xRange = (expected.dx - delta)...(expected.dz + delta)
    let zRange = (expected.dx - delta)...(expected.dz + delta)
    let altRange = (expected.dAlt - delta)...(expected.dAlt + delta)
    return xRange ~= actual.dx &&
           zRange ~= actual.dz &&
           altRange ~= actual.dAlt
  }
}
