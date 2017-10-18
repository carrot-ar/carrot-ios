//
//  Sendable.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/18/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

enum Sendable<T: Codable> {
  case message(Message<T>, SessionToken, Location2D)
}

extension Sendable: Codable {
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  enum CodingKeys: String, CodingKey {
    case message
    case token
    case origin
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    guard let message = try? values.decode(Message<T>.self, forKey: .message),
          let token = try? values.decode(SessionToken.self, forKey: .token),
          let origin = try? values.decode(Location2D.self, forKey: .origin)
    else {
      throw CodingError.decoding("Decoding Failed. \(dump(values))")
      
    }
    self = .message(message, token, origin)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .message(message, token, origin):
      try container.encode(message, forKey: .message)
      try container.encode(token, forKey: .token)
      try container.encode(origin, forKey: .origin)
    }
  }
}
