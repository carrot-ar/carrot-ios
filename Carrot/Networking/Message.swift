//
//  Message.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/15/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

public enum MessageError: Error {
  case jsonError
  case badKey(String)
}

public struct Message {
  public let endpoint: String?
  public let info: JSONDict
  
  public init(endpoint: String? = nil, jsonConvertible: JSONConvertible) {
    self.endpoint = endpoint
    self.info = jsonConvertible.makeJSON()
  }
  
  public init(endpoint: String? = nil, info: JSONDict) {
    self.endpoint = endpoint
    self.info = info
  }
  
  init(data: Data) throws {
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    guard let jsonDict = object as? JSONDict else {
      throw MessageError.jsonError
    }
    let endpoint = jsonDict["end_point"] as? String
    guard let info = jsonDict["info"] as? JSONDict else {
      throw MessageError.badKey("info")
    }
    self.init(endpoint: endpoint, info: info)
  }
  
  func data() throws -> Data {
    var dict = JSONDict()
    if let endpoint = endpoint {
      dict["end_point"] = endpoint
    }
    dict["info"] = info
    return try JSONSerialization.data(withJSONObject: dict, options: [])
  }
}

public protocol JSONConvertible: class {
  init?(json: JSONDict)
  func makeJSON() -> JSONDict
}

public typealias JSONDict = [String: Any]
