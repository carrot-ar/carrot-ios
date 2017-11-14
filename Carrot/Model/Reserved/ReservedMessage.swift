//
//  ReservedMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/14/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import Parrot

// MARK: - ReservedMessage

enum ReservedMessage {
  case beacon(BeaconInfo)
  case transform(Location3D)
}

// MARK: - Codable

extension ReservedMessage: Codable {
  
  enum CodingKeys: String, CodingKey {
    case offset
    case object = "params"
  }
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    if let beaconInfo = try? values.decode(BeaconInfo.self, forKey: .object) {
      self = .beacon(beaconInfo)
      return
    }
    if let location = try? values.decode(Location3D.self, forKey: .offset) {
      self = .transform(location)
      return
    }
    throw CodingError.decoding("Decoding Failed. \(dump(values))")
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .beacon(beaconInfo):
      try container.encode(beaconInfo, forKey: .object)
    case let .transform(location):
      try container.encode(location, forKey: .offset)
    }
  }
}
