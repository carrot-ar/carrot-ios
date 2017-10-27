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

class FailingSyncLocationRequester: LocationRequester {
  
  init() { }
  
  enum LocationError: Error {
    case generic
  }
  
  func fetch(result: @escaping (Result<CLLocation>) -> Void) {
    let wrapped: Result<CLLocation> = retrying ? .success(CLLocation()) : .error(LocationError.generic)
    retrying = true
    result(wrapped)
  }
  
  private var retrying = false
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
  var failingSession: CarrotSession<TextMessage>!
  var retryingSession: CarrotSession<TextMessage>!
  var restartingSession: CarrotSession<TextMessage>!

  override func setUp() {
    super.setUp()
    socket = SyncEchoSocket()
    session = CarrotSession<TextMessage>(
      socket: socket,
      locationRequester: SyncLocationRequester(),
      messageHandler: { _, _ in },
      errorHandler: { _, _ in return nil }
    )
    failingSession = CarrotSession<TextMessage>(
      socket: socket,
      locationRequester: FailingSyncLocationRequester(),
      messageHandler: { _, _ in },
      errorHandler: { _, _ in return nil }
    )
    retryingSession = CarrotSession<TextMessage>(
      socket: socket,
      locationRequester: FailingSyncLocationRequester(),
      messageHandler: { _, _ in },
      errorHandler: { _, _ in return .retry }
    )
    restartingSession = CarrotSession<TextMessage>(
      socket: socket,
      locationRequester: FailingSyncLocationRequester(),
      messageHandler: { _, _ in },
      errorHandler: { _, _ in return .restart }
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
        assert(false, "Unexpected state: \(state)")
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
  
  func testFailsForLocationError() {
    let openingExpectation = XCTestExpectation(description: "Opening")
    let pendingTokenExpectation = XCTestExpectation(description: "Pending token")
    let receivedTokenExpectation = XCTestExpectation(description: "Received token")
    let fetchingLocationExpectation = XCTestExpectation(description: "Fetching location")
    let failingExpectation = XCTestExpectation(description: "Failed")
    failingSession.start { [weak self] state in
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
      case .failed:
        failingExpectation.fulfill()
      default:
        assert(false, "Unexpected state: \(state)")
        return
      }
    }
    wait(for: [openingExpectation,
               pendingTokenExpectation,
               receivedTokenExpectation,
               fetchingLocationExpectation,
               failingExpectation],
         timeout: 0.5,
         enforceOrder: true)
  }
  
  func testRetriesLocationWhenFailsAndAsked() {
    let openingExpectation = XCTestExpectation(description: "Opening")
    let pendingTokenExpectation = XCTestExpectation(description: "Pending token")
    let receivedTokenExpectation = XCTestExpectation(description: "Received token")
    let fetchingLocationExpectation = XCTestExpectation(description: "Fetching location")
    let failingExpectation = XCTestExpectation(description: "Failed but retrying")
    let authenticatedExpectation = XCTestExpectation(description: "Authenticated")
    retryingSession.start { [weak self] state in
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
      case .failed:
        failingExpectation.fulfill()
      case .authenticated:
        authenticatedExpectation.fulfill()
      default:
        assert(false, "Unexpected state: \(state)")
        return
      }
    }
    wait(for: [openingExpectation,
               pendingTokenExpectation,
               receivedTokenExpectation,
               fetchingLocationExpectation,
               failingExpectation,
               authenticatedExpectation],
         timeout: 1,
         enforceOrder: true)
  }
  
  func testRestartingSession() {
    let openingExpectation = XCTestExpectation(description: "Opening")
    let pendingTokenExpectation = XCTestExpectation(description: "Pending token")
    let receivedTokenExpectation = XCTestExpectation(description: "Received token")
    let fetchingLocationExpectation = XCTestExpectation(description: "Fetching location")
    let failingExpectation = XCTestExpectation(description: "Failed but retrying")
    let openingExpectation2 = XCTestExpectation(description: "Opening again")
    let pendingTokenExpectation2 = XCTestExpectation(description: "Pending token again")
    let receivedTokenExpectation2 = XCTestExpectation(description: "Received token again")
    let fetchingLocationExpectation2 = XCTestExpectation(description: "Fetching location again")
    let authenticatedExpectation = XCTestExpectation(description: "Authenticated")
    var onRetry = false
    restartingSession.start { [weak self] state in
      switch state {
      case .opening:
        if onRetry {
          openingExpectation2.fulfill()
        } else {
          openingExpectation.fulfill()
        }
      case .pendingToken:
        if onRetry {
          pendingTokenExpectation2.fulfill()
        } else {
          pendingTokenExpectation.fulfill()
        }
        try! self?.socket.send(data: Data("session-token".utf8))
      case .receivedToken:
        if onRetry {
          receivedTokenExpectation2.fulfill()
        } else {
          receivedTokenExpectation.fulfill()
        }
      case .fetchingLocation:
        if onRetry {
          fetchingLocationExpectation2.fulfill()
        } else {
          fetchingLocationExpectation.fulfill()
        }
      case .failed:
        onRetry = true
        failingExpectation.fulfill()
      case .authenticated:
        authenticatedExpectation.fulfill()
      default:
        assert(false, "Unexpected state: \(state)")
        return
      }
    }
    wait(for: [openingExpectation,
               pendingTokenExpectation,
               receivedTokenExpectation,
               fetchingLocationExpectation,
               failingExpectation,
               authenticatedExpectation],
         timeout: 1,
         enforceOrder: true)
  }
  
  func testNonAuthorizedMessageThrows() {
    let message = Message<TextMessage>(location: nil, object: TextMessage(text: "😡"))
    XCTAssertThrowsError(try session.send(message: message, to: "endpoint"))
  }
}
