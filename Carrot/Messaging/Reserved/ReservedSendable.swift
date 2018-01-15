//
//  ReservedSendable.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/14/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - ReservedSendable

struct ReservedSendable {
  var token: SessionToken
  var endpoint: ReservedEndpoint
  var message: ReservedMessage
  
  init(token: SessionToken, endpoint: ReservedEndpoint, message: ReservedMessage) {
    self.token = token
    self.message = message
    self.endpoint = endpoint
  }
  
  init(token: SessionToken, message: ReservedMessage) {
    self.token = token
    self.message = message
    switch message {
    case .transform:
      endpoint = .transform
    case .beacon:
      endpoint = .beacon
    case .none:
      fatalError("ERROR: Cannot infer the endpoint for ReservedMessage.none.")
    }
  }
}

// MARK: - ReservedEndpoint

enum ReservedEndpoint: String, Codable {
  case transform = "carrot_transform"
  case beacon = "carrot_beacon"
}

// MARK: - Codable

extension ReservedSendable: Codable {
 
  enum CodingKeys: String, CodingKey {
    case token = "session_token"
    case endpoint
    case message = "payload"
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    token = try values.decode(SessionToken.self, forKey: .token)
    endpoint = try values.decode(ReservedEndpoint.self, forKey: .endpoint)
    message = (try? values.decode(ReservedMessage.self, forKey: .message)) ?? .none
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(token, forKey: .token)
    try container.encode(endpoint, forKey: .endpoint)
    try container.encode(message, forKey: .message)
  }
}
