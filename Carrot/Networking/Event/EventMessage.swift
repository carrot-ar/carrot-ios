//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - EventMessage

public struct EventMessage<T: Codable> {
  
  // MARK: Lifecycle
  
  public init(endpoint: String, location: Location3D, object: T) {
    self.endpoint = endpoint
    self.location = location
    self.object = object
  }
  
  // MARK: Public
  
  public var endpoint: String?
  public var location: Location3D
  public var object: T
}

// MARK: - Codable

extension EventMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case endpoint
    case location
    case object = "params"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    endpoint = try values.decode(String?.self, forKey: .endpoint)
    location = try values.decode(Location3D.self, forKey: .location)
    object = try values.decode(T.self, forKey: .object)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(endpoint, forKey: .endpoint)
    try container.encode(location, forKey: .location)
    try container.encode(object, forKey: .object)
  }
}
