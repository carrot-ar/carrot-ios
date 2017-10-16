//
//  Socket.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

public protocol SocketDelegate: class {
  func socketDidOpen()
  func socketDidClose()
  func socketDidReceive(data: Data)
}

public protocol Socket: class {
  weak var eventDelegate: SocketDelegate? { get set }
  func open()
  func close()
  func send(data: Data) throws
}
