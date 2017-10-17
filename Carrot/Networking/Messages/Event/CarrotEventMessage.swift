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
  
  init(from message: EventMessage<T>, token: SessionToken, origin: Location2D) {
    self.token = token
    self.origin = origin
    self.message = message
  }
  
  // MARK: Internal
  
  var origin: Location2D
  var token: SessionToken
  var message: EventMessage<T>
}

// MARK: - Codable

extension CarrotEventMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case origin
    case token
    case message
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    origin = try values.decode(Location2D.self, forKey: .origin)
    token = try values.decode(SessionToken.self, forKey: .token)
    message = try values.decode(EventMessage<T>.self, forKey: .message)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(origin, forKey: .origin)
    try container.encode(token, forKey: .token)
    try container.encode(message, forKey: .message)
  }
}
