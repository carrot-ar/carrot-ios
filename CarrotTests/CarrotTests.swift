//
//  CarrotTestsTests.swift
//  CarrotTests
//
//  Created by Gonzalo Nunez on 11/14/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

@testable import Carrot
@testable import Parrot
import simd
import XCTest

struct A: Codable {
  var foo: String
}

class CarrotTests: XCTestCase {
  
  let token = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
  
  func data(from dict: [String: Any]) throws -> Data {
    return try JSONSerialization.data(withJSONObject: dict, options: [])
  }
  
  func testSendableDecoding() {
    let dict = [
      "session_token": token.uuidString,
      "endpoint": "test_endpoint",
      "payload": [
        "transform": [
          "c0": [1, 2, 3, 4],
          "c1": [1, 2, 3, 4],
          "c2": [1, 2, 3, 4],
          "c3": [1, 2, 3, 4]
        ],
        "params": [
          "foo": "bar"
        ]
      ]
    ] as [String: Any]
    XCTAssertNoThrow(try JSONDecoder().decode(Sendable<A>.self, from: data(from: dict)))
  }
  
  func testSendableEncoding() {
    let sendable = Sendable(token: token, endpoint: "foo", message: Message(transform: nil, object: A(foo: "bar")))
    XCTAssertNoThrow(try JSONEncoder().encode(sendable))
  }
  
  func testReservedSendableDecoding() {
    let dict = [
      "session_token": token.uuidString,
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
  
  func testReservedSendableDecodingExampleFromServer() {
    let dict = [
      "session_token": "E628E5F8-C36C-496A-93FC-0C247A3E6E5F",
      "endpoint": "carrot_transform",
      "payload": [
        "params": [
          "uuid": "E628E5F8-C36C-496A-93FC-0C247A3E6E5F",
          "identifier": "com.Carrot.Beacon"
        ]
      ]
    ] as [String: Any]
    XCTAssertNoThrow(try JSONDecoder().decode(ReservedSendable.self, from: data(from: dict)))
    let decoded = try! JSONDecoder().decode(ReservedSendable.self, from: data(from: dict))
    XCTAssertEqual(decoded.token.uuidString, "E628E5F8-C36C-496A-93FC-0C247A3E6E5F")
  }
  
  func testReservedSendableNoPayloadDecoding() {
    let dict = ["session_token": token.uuidString,
                "endpoint": "carrot_transform"] as [String: Any]
    XCTAssertNoThrow(try JSONDecoder().decode(ReservedSendable.self, from: data(from: dict)))
  }
  
  func testReservedSendableEncoding() {
    let sendable = ReservedSendable(token: token, message: .transform(matrix_identity_float4x4))
    XCTAssertNoThrow(try JSONEncoder().encode(sendable))
  }
  
  func testReservedSendableEndpoint() {
    var sendable = ReservedSendable(token: token, message: .transform(matrix_identity_float4x4))
    switch sendable.endpoint {
    case .transform:
      break
    case .beacon:
      XCTAssert(false, "Unexpected endpoint type")
    }
   sendable = ReservedSendable(
    token: token,
    message: .beacon(BeaconInfo(
      uuid: token,
      identifier: "com.Carrot.Beacon",
      params: .none))
    )
    switch sendable.endpoint {
    case .beacon:
      break
    case .transform:
      XCTAssert(false, "Unexpected endpoint type")
    }
  }
}
