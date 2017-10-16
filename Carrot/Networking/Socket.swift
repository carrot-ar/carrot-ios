//
//  Socket.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

// MARK: - Socket

public protocol Socket: class {
  weak var eventDelegate: SocketDelegate? { get set }
  func open()
  func close()
  func send(data: Data) throws
}

// MARK: - SocketDelegate

public protocol SocketDelegate: class {
  func socketDidOpen()
  func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?)
  func socketDidFail(with error: Error?)
  func socketDidReceive(data: Data)
}

// MARK: - Socket + String

public enum SocketError: Error {
  case stringEncodingFailure
}

extension Socket {
  func send(string: String, with encoding: String.Encoding = .utf8) throws {
    guard let data = string.data(using: encoding) else {
      throw SocketError.stringEncodingFailure
    }
    try send(data: data)
  }
}
