//
//  CarrotEventMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - CarrotEventMessage

struct CarrotEventMessage<T: Codable> {
  
  // MARK: Lifecycle
  
  init(from message: EventMessage<T>, origin: Location2D) {
    self.message = message
    self.origin = origin
  }
  
  // MARK: Internal
  
  var origin: Location2D
  var message: EventMessage<T>
}

// MARK: - Codable

extension CarrotEventMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case message
    case origin
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    message = try values.decode(EventMessage<T>.self, forKey: .message)
    origin = try values.decode(Location2D.self, forKey: .origin)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(message, forKey: .message)
    try container.encode(origin, forKey: .origin)
  }
}
