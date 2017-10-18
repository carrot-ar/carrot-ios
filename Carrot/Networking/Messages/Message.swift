//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - Message

public enum Message<T: Codable> {
  case event(EventMessage<T>)
  case stream(StreamMessage<T>)
}

// MARK: - Codable

extension Message: Codable {
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  enum CodingKeys: String, CodingKey {
    case event
    case stream
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.singleValueContainer()
    if let eventMessage = try? values.decode(EventMessage<T>.self) {
      self = .event(eventMessage)
      return
    }
    if let streamMessage = try? values.decode(StreamMessage<T>.self) {
      self = .stream(streamMessage)
      return
    }
    throw CodingError.decoding("Decoding Failed. \(dump(values))")
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .event(message):
      try container.encode(message, forKey: .event)
    case let .stream(message):
      try container.encode(message, forKey: .stream)
    }
  }
}
