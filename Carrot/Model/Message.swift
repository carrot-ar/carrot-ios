//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/8/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - Message

public struct Message<T: Codable> {
  var location: Location3D?
  var object: T
}

// MARK: - Codable

extension Message: Codable {
  
  enum CodingKeys: String, CodingKey {
    case offset
    case object = "params"
  }
  
 public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    location = try values.decode(Location3D?.self, forKey: .offset)
    object = try values.decode(T.self, forKey: .object)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(location, forKey: .offset)
    try container.encode(object, forKey: .object)
  }
}
