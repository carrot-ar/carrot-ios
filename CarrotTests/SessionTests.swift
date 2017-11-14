//
//  SessionTests.swift
//  CarrotTests
//
//  Created by Gonzalo Nunez on 11/14/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

import XCTest
@testable import Carrot

struct A: Codable {
  var foo: String
}

class SessionTests: XCTestCase {
  
  let token = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
  
  func data(from dict: [String: Any]) throws -> Data {
    return try JSONSerialization.data(withJSONObject: dict, options: [])
  }
  
  func testSendableDecoding() {
    let dict = [
      "session_token": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
      "endpoint": "test_endpoint",
      "payload": [
        "offset": [
          "x": 0,
          "y": 0,
          "z": 0
        ],
        "params": [
          "foo": "bar"
        ]
      ]
    ] as [String: Any]
    XCTAssertNoThrow(try JSONDecoder().decode(Sendable<A>.self, from: data(from: dict)))
  }
  
  func testSendableEncoding() {
    let sendable = Sendable(token: token, endpoint: "foo", message: Message(location: nil, object: A(foo: "bar")))
    XCTAssertNoThrow(try JSONEncoder().encode(sendable))
  }
  
  func testReservedSendableDecoding() {
    let dict = [
      "session_token": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
      "endpoint": "carrot_transform",
      "payload": [
        "offset": [
          "x": 0,
          "y": 0,
          "z": 0
        ]
      ]
    ] as [String: Any]
    XCTAssertNoThrow(try JSONDecoder().decode(ReservedSendable.self, from: data(from: dict)))
  }
  
  func testReservedSendableEncoding() {
    let sendable = ReservedSendable(token: token, endpoint: .transform, message: .transform(Location3D(x: 1, y: 2, z: 1)))
    XCTAssertNoThrow(try JSONEncoder().encode(sendable))
  }
}
