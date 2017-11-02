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

