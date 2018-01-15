//
//  MessageResult.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 1/15/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import Foundation

public enum MessageResult<T: Codable> {
  case success(Message<T>, Endpoint?)
  case error(Error)
}
