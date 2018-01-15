//
//  CarrotSession.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 1/15/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import Foundation
import simd

public final class CarrotSession<T: Codable>: CustomCarrotSession<PicnicProtocol, T> {
  
  // MARK: Lifecycle
  
  public init(
    socket: Socket,
    currentTransform: @escaping () -> matrix_float4x4?,
    messageHandler: @escaping (MessageResult<T>) -> Void,
    errorHandler: @escaping (PicnicProtocol.State?, Error) -> Void)
  {
    let picnicProtocol = PicnicProtocol(socket: socket, currentTransform: currentTransform)
    super.init(
      socket: socket,
      driver: picnicProtocol,
      messageHandler: messageHandler,
      errorHandler: errorHandler)
  }
}
