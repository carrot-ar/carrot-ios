//
//  CarrotStreamMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - CarrotStreamMessage

struct CarrotStreamMessage<T: Codable> {
  
  // MARK: Lifecycle
  
  init(from message: StreamMessage<T>, origin: Location2D) {
    self.message = message
    self.origin = origin
  }
  
  // MARK: Internal
  
  var origin: Location2D
  var message: StreamMessage<T>
}

// MARK: - Codable

extension CarrotStreamMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case message
    case origin
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    origin = try values.decode(Location2D.self, forKey: .origin)
    message = try values.decode(StreamMessage<T>.self, forKey: .message)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(origin, forKey: .origin)
    try container.encode(message, forKey: .message)
  }
}
