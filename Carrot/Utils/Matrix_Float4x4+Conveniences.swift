//
//  Matrix_Float4x4+Conveniences.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import simd
import GLKit

extension matrix_float4x4 {
  
  var position: float4 {
    return columns.3
  }
}
