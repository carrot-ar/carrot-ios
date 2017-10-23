//
//  MatrixOperations.swift
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

// MARK: - Translatable

extension matrix_float4x4: Translatable {
  mutating func translate(with operation: AxisOperation) {
    var mat = matrix_identity_float4x4
    switch operation {
    case let .by(factor, along: axis):
      switch axis {
      case .x:
        mat.columns.3.x = factor
      case .y:
        mat.columns.3.y = factor
      case .z:
        mat.columns.3.z = factor
      }
    }
    self = simd_mul(self, mat)
  }
}

// MARK: - Rotatable

extension matrix_float4x4: Rotatable {
  mutating func rotate(with operation: AxisOperation) {
    let glkMatrix: GLKMatrix4
    switch operation {
    case let .by(radians, along: axis):
      switch axis {
      case .x:
        glkMatrix = GLKMatrix4RotateX(GLKMatrix4Identity, radians)
      case .y:
        glkMatrix = GLKMatrix4RotateY(GLKMatrix4Identity, radians)
      case .z:
        glkMatrix = GLKMatrix4RotateZ(GLKMatrix4Identity, radians)
      }
    }
    let mat = matrix_float4x4(glkMatrix: glkMatrix)
    self = simd_mul(self, mat)
  }
}

// MARK: - Initializers

extension GLKMatrix4 {
  init(matrix: matrix_float4x4) {
    let m = (matrix.columns.0.x, matrix.columns.1.x, matrix.columns.2.x, matrix.columns.3.x,
             matrix.columns.0.y, matrix.columns.1.y, matrix.columns.2.y, matrix.columns.3.y,
             matrix.columns.0.z, matrix.columns.1.z, matrix.columns.2.z, matrix.columns.3.z,
             matrix.columns.0.w, matrix.columns.1.w, matrix.columns.2.w, matrix.columns.3.w)
    self.init(m: m)
  }
}

extension matrix_float4x4 {
  init(glkMatrix: GLKMatrix4) {
    self.init(rows: [
      float4(glkMatrix.m00, glkMatrix.m01, glkMatrix.m02, glkMatrix.m03),
      float4(glkMatrix.m10, glkMatrix.m11, glkMatrix.m12, glkMatrix.m13),
      float4(glkMatrix.m20, glkMatrix.m21, glkMatrix.m22, glkMatrix.m23),
      float4(glkMatrix.m30, glkMatrix.m31, glkMatrix.m32, glkMatrix.m33)])
  }
}
