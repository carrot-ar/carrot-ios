//
//  SessionTests.swift
//  CarrotTests
//
//  Created by Gonzalo Nunez on 10/24/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import XCTest
import Carrot
import CoreLocation

class SyncLocationRequester: LocationRequester {
  
  func fetch(result: @escaping (Result<CLLocation>) -> Void) {
    result(.success(CLLocation()))
  }
}

class SyncEchoSocket: Socket {
  
  init() { }
  
  weak var eventDelegate: SocketDelegate?
  
  func open() {
    eventDelegate?.socketDidOpen()
  }
  
  func close() {
    eventDelegate?.socketDidClose(with: 0, reason: nil, wasClean: nil)
  }
  
  func send(data: Data) throws {
    eventDelegate?.socketDidReceive(data: data)
  }
}

struct TextMessage: Codable {
  var text: String
}

class SessionTests: XCTestCase {
  
  var socket: SyncEchoSocket!
  var session: CarrotSession<TextMessage>!
  
  override func setUp() {
    super.setUp()
    socket = SyncEchoSocket()
    session = CarrotSession<TextMessage>(
      socket: socket,
      locationRequester: SyncLocationRequester(),
      messageHandler: { _, _ in },
      errorHandler: { _, _ in return nil }
    )
  }
  
  func testHandshake() {
    let openingExpectation = XCTestExpectation(description: "Opening")
    let pendingTokenExpectation = XCTestExpectation(description: "Pending token")
    let receivedTokenExpectation = XCTestExpectation(description: "Received token")
    let fetchingLocationExpectation = XCTestExpectation(description: "Fetching location")
    let authenticatedExpectation = XCTestExpectation(description: "Authenticated")
    session.start { [weak self] state in
      switch state {
      case .opening:
        openingExpectation.fulfill()
      case .pendingToken:
        pendingTokenExpectation.fulfill()
        try! self?.socket.send(data: Data("session-token".utf8))
      case .receivedToken:
        receivedTokenExpectation.fulfill()
      case .fetchingLocation:
        fetchingLocationExpectation.fulfill()
      case .authenticated:
        authenticatedExpectation.fulfill()
      default:
        assert(false, "Unexpected state during handshake: \(state)")
        return
      }
    }
    wait(for: [openingExpectation,
               pendingTokenExpectation,
               receivedTokenExpectation,
               fetchingLocationExpectation,
               authenticatedExpectation],
         timeout: 0.5,
         enforceOrder: true)
  }
  
  func testNonAuthorizedMessageThrows() {
    let message = Message<TextMessage>(location: nil, object: TextMessage(text: "😡"))
    XCTAssertThrowsError(try session.send(message: message, to: "endpoint"))
  }
}
