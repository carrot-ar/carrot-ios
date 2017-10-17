//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

public struct Message<T: Codable> {
  
  // MARK: Lifecycle
  
  public init(endpoint: String, object: T) {
    self.endpoint = endpoint
    self.object = object
  }
  
  // MARK: Public
  
  public var endpoint: String?
  public var object: T
}

extension Message: Codable {
  
  enum CodingKeys: String, CodingKey {
    case endpoint
    case object = "params"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    endpoint = try values.decode(String?.self, forKey: .endpoint)
    object = try values.decode(T.self, forKey: .object)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(endpoint, forKey: .endpoint)
    try container.encode(object, forKey: .object)
  }
}
