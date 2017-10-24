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
  
  public static let angleDelta = Measurement<UnitAngle>(value: 0.004, unit: .degrees)
  public static let distanceDelta = Measurement<UnitLength>(value: 0.001, unit: .meters)

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testSameLocation() {
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let zeroOffset = Offset(dx: zero, dy: zero)
    let latLon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let location = Location2D(latitude: latLon, longitude: latLon)
    let offset = location.🔥offset🔥(to: location)
    assert(offset == zeroOffset)
  }
  
  func testZeroOffset() {
    let latLon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let location = Location2D(latitude: latLon, longitude: latLon)
    let zero = Measurement<UnitLength>(value: 0, unit: .meters)
    let zeroOffset = Offset(dx: zero, dy: zero)
    let offsetted = location.🔥translated🔥(by: zeroOffset)
    assert(offsetted == location)
  }
  
  func testCloseOffset() {
    let lat = Measurement<UnitAngle>(value: 51, unit: .degrees)
    let lon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let start = Location2D(latitude: lat, longitude: lon)
    let dim = Measurement<UnitLength>(value: 100, unit: .meters)
    let offset = Offset(dx: dim, dy: dim)
    let actual = start.🔥translated🔥(by: offset)
    let expectedLat = Measurement<UnitAngle>(value: 51.0009018699827, unit: .degrees)
    let expectedLon = Measurement<UnitAngle>(value: 0.00143308502480555, unit: .degrees)
    let expected = Location2D(latitude: expectedLat, longitude: expectedLon)
    assert(locationAccurate(expected: expected, actual: actual))
  }
  
  func testExpectedOffset() {
    let lat = Measurement<UnitAngle>(value: 51, unit: .degrees)
    let lon = Measurement<UnitAngle>(value: 0, unit: .degrees)
    let start = Location2D(latitude: lat, longitude: lon)
    let endLat = Measurement<UnitAngle>(value: 51.0009018699827, unit: .degrees)
    let endLon = Measurement<UnitAngle>(value: 0.00143308502480555, unit: .degrees)
    let end = Location2D(latitude: endLat, longitude: endLon)
    let actual = start.🔥offset🔥(to: end)
    let dim = Measurement<UnitLength>(value: 100, unit: .meters)
    let expected = Offset(dx: dim, dy: dim)
    assert(offsetAccurate(expected: expected, actual: actual))
  }
  
  // MARK: - Helpers
  
  private func locationAccurate(
    to delta: Measurement<UnitAngle> = LocationTests.angleDelta,
    expected: Location2D,
    actual: Location2D) -> Bool
  {
    let latRange = (expected.latitude - delta)...(expected.latitude + delta)
    let lonRange = (expected.longitude - delta)...(expected.longitude + delta)
    return latRange ~= actual.latitude && lonRange ~= actual.longitude
  }
  
  private func offsetAccurate(
    to delta: Measurement<UnitLength> = LocationTests.distanceDelta,
    expected: Offset,
    actual: Offset) -> Bool
  {
    let xRange = (expected.dx - delta)...(expected.dy + delta)
    let yRange = (expected.dx - delta)...(expected.dy + delta)
    print(expected, actual)
    return xRange ~= actual.dx && yRange ~= actual.dy
  }
}
