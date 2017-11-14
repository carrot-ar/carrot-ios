//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/8/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

public enum Message<T: Codable> {
  case offset(Location3D)
  case object(T)
  case full(Location3D?, T)
}

extension Message: Codable {
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  enum CodingKeys: String, CodingKey {
    case offset
    case object = "params"
  }
  
 public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let location = try? values.decode(Location3D.self, forKey: .offset)
    let object = try? values.decode(T.self, forKey: .object)
    switch (location, object) {
    case (.none, .none):
      throw CodingError.decoding("Decoding Failed. \(dump(values))")
    case let (location?, .none):
      self = .offset(location)
    case let (.none, object?):
      self = .object(object)
    case let (location, object?):
      self = .full(location, object)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .offset(location):
      try container.encode(location, forKey: .offset)
    case let .object(object):
      try container.encode(object, forKey: .object)
    case let .full(location, object):
      try container.encode(location, forKey: .offset)
      try container.encode(object, forKey: .object)
    }
  }
}
