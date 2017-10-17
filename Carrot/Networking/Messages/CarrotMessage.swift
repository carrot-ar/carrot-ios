//
//  CarrotMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - CarrotMessage

enum CarrotMessage<T: Codable> {
  case event(CarrotEventMessage<T>)
  case stream(CarrotStreamMessage<T>)
}

// MARK: - Codable

extension CarrotMessage: Codable {
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  enum CodingKeys: String, CodingKey {
    case event
    case stream
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    if let eventMessage = try? values.decode(CarrotEventMessage<T>.self, forKey: .event) {
      self = .event(eventMessage)
      return
    }
    
    if let streamMessage = try? values.decode(CarrotStreamMessage<T>.self, forKey: .stream) {
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
