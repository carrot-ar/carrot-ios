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
  public let params: JSONDict
  
  public init(endpoint: String? = nil, jsonConvertible: JSONConvertible) {
    self.endpoint = endpoint
    self.params = jsonConvertible.makeJSON()
  }
  
  public init(endpoint: String? = nil, params: JSONDict) {
    self.endpoint = endpoint
    self.params = params
  }
  
  init(data: Data) throws {
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    guard let jsonDict = object as? JSONDict else {
      throw MessageError.jsonError
    }
    let endpoint = jsonDict["end_point"] as? String
    guard let params = jsonDict["params"] as? JSONDict else {
      throw MessageError.badKey("params")
    }
    self.init(endpoint: endpoint, params: params)
  }
  
  func data() throws -> Data {
    var dict = JSONDict()
    if let endpoint = endpoint {
      dict["end_point"] = endpoint
    }
    dict["params"] = params
    return try JSONSerialization.data(withJSONObject: dict, options: [])
  }
}

public protocol JSONConvertible: class {
  init?(json: JSONDict)
  func makeJSON() -> JSONDict
}

public typealias JSONDict = [String: Any]
