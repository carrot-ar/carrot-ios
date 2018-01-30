//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/8/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import simd

// MARK: - Message

public struct Message<T: Codable> {
  public var transform: matrix_float4x4?
  public var object: T
  
  public init(transform: matrix_float4x4?, object: T) {
    self.transform = transform
    self.object = object
  }
}

// MARK: - Codable

extension Message: Codable {
  
  enum CodingKeys: String, CodingKey {
    case transform
    case object = "params"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    transform = try values.decode(matrix_float4x4?.self, forKey: .transform)
    object = try values.decode(T.self, forKey: .object)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(transform, forKey: .transform)
    try container.encode(object, forKey: .object)
  }
}
