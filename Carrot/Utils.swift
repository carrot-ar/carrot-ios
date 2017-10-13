//
//  Utils.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation

public enum Result<T> {
  case success(T)
  case error(Error)
}
