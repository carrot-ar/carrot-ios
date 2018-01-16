//
//  MatrixUtils.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import simd

extension matrix_float4x4: Codable {
  
  var position: float4 {
    return columns.3
  }
  
  enum CodingKeys: String, CodingKey {
    case c0
    case c1
    case c2
    case c3
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let c0 = try container.decode(Array<Float>.self, forKey: .c0)
    let c1 = try container.decode(Array<Float>.self, forKey: .c1)
    let c2 = try container.decode(Array<Float>.self, forKey: .c2)
    let c3 = try container.decode(Array<Float>.self, forKey: .c3)
    let tuples = [c0, c1, c2, c3].map { simd_float4($0) }
    self.columns = (tuples[0], tuples[1], tuples[2], tuples[3])
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let c0 = self.columns.0
    try container.encode([c0.x, c0.y, c0.z, c0.w], forKey: .c0)
    let c1 = self.columns.1
    try container.encode([c1.x, c1.y, c1.z, c1.w], forKey: .c1)
    let c2 = self.columns.2
    try container.encode([c2.x, c2.y, c2.z, c2.w], forKey: .c2)
    let c3 = self.columns.3
    try container.encode([c3.x, c3.y, c3.z, c3.w], forKey: .c3)
  }
}
