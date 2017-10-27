//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - Message

public struct Message<T: Codable> {
  
  // MARK: Lifecycle
  
  public init(location: Location3D?, object: T) {
    self.location = location
    self.object = object
  }
  
  // MARK: Public
  
  public var location: Location3D?
  public var object: T
  
  // MARK: Internal
  
  var offset: Offset? {
    guard let loc = location else {
      return nil
    }
    let dx = loc.x
    let dz = loc.z
    let alt = loc.altitude
    return Offset(
      dx: Measurement<UnitLength>(value: dx, unit: .meters),
      dz: Measurement<UnitLength>(value: dz, unit: .meters),
      dAlt: Measurement<UnitLength>(value: alt, unit: .meters))
  }
  
  /// Returns a `Message<T>` with a location that's been converted from being based off of `foreignOrigin` to `origin`.
  func localized(from foreignOrigin: Location2D, to origin: Location2D) -> Message<T> {
    guard let offset = offset else { return self }
    var copy = self
    let foreignLocation = foreignOrigin.translated(by: offset)
    let newOffset = origin.offset(to: foreignLocation)
    copy.location = Location3D(
      x: newOffset.dx.value,
      z: newOffset.dz.value,
      altitude: newOffset.dAlt.value)
    return copy
  }
}

// MARK: - Codable

extension Message: Codable {
  
  enum CodingKeys: String, CodingKey {
    case location = "offset"
    case object = "params"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    location = try values.decode(Location3D?.self, forKey: .location)
    object = try values.decode(T.self, forKey: .object)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(location, forKey: .location)
    try container.encode(object, forKey: .object)
  }
}

