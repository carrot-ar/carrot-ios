//
//  InitialMessage.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/1/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - InitialMessage

struct InitialMessage {
  var token: UUID
  var primaryBeacon: CLBeaconRegion?
}

// MARK: - Codable

extension InitialMessage: Codable {
  
  enum CodingError: Error {
    case decoding(String)
  }
  
  enum CodingKeys: String, CodingKey {
    case token
    case primaryBeacon = "primary_beacon"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let tokenStr = try values.decode(String.self, forKey: .token)
    guard let uuid = UUID(uuidString: tokenStr) else {
      throw CodingError.decoding("Failed to instantiate UUID from \(tokenStr)")
    }
    token = uuid
    primaryBeacon = try values.decode(CLBeaconRegion?.self, forKey: .primaryBeacon)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(token.uuidString, forKey: .token)
    try container.encode(primaryBeacon, forKey: .primaryBeacon)
  }
}
