//
//  ReservedMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/14/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import Parrot
import simd

// MARK: - ReservedMessage

enum ReservedMessage {
  case none
  case beacon(BeaconInfo)
  case transform(matrix_float4x4)
}

// MARK: - Codable

extension ReservedMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case transform
    case object = "params"
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    if let beaconInfo = try? values.decode(BeaconInfo.self, forKey: .object) {
      self = .beacon(beaconInfo)
      return
    }
    if let transform = try? values.decode(matrix_float4x4.self, forKey: .transform) {
      self = .transform(transform)
      return
    }
    self = .none
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .beacon(beaconInfo):
      try container.encode(beaconInfo, forKey: .object)
    case let .transform(transform):
      try container.encode(transform, forKey: .transform)
    case .none:
      break
    }
  }
}
