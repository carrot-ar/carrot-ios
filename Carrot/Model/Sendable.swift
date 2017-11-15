//
//  Sendable.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/18/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - Sendable

struct Sendable<T: Codable> {
  var token: SessionToken
  var endpoint: String
  var message: Message<T>
}

// MARK: - Codable

extension Sendable: Codable {
  
  enum CodingKeys: String, CodingKey {
    case token = "session_token"
    case endpoint
    case message = "payload"
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    token = try values.decode(SessionToken.self, forKey: .token)
    endpoint = try values.decode(String.self, forKey: .endpoint)
    message = try values.decode(Message<T>.self, forKey: .message)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(token, forKey: .token)
    try container.encode(endpoint, forKey: .endpoint)
    try container.encode(message, forKey: .message)
  }
}
