//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 1/31/23.
//

import Foundation
import UIKit
import Metal
import simd

// MARK: - Command

public enum LightDirection: Int {
  case ambient = 1
  case directional = 2
  case point = 3
}

final class PlaceLight: MetalDrawable {
  var id: String
  var transform: MetalDrawableData.Transform
  let direction: LightDirection
  var color: simd_float4
  var animations: [NodeTransition]?

  private(set) var uniformValues: Light?
  private var previousUniformValues: Light?
  
  init(
    id: String,
    transform: MetalDrawableData.Transform,
    direction: LightDirection,
    color: simd_float4,
    animations: [NodeTransition]?
  ) {
    self.id = id
    self.transform = transform
    self.direction = direction
    self.color = color
    self.animations = animations
  }
}

// MARK: - Updates

extension PlaceLight {  
  var needsRender: Bool { false }
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?) {
    fatalError()
  }
  
  private func makeUniformValues() -> Light {
    let position = switch direction {
    case .ambient:
      simd_float4(.zero, Float(direction.rawValue))
    case .directional:
      simd_float4(transform.rotation.act(.back), Float(direction.rawValue))
    case .point:
      simd_float4(transform.translation, Float(direction.rawValue))
    }
    
    return Light(position: position, color: color)
  }
  
  func update(time: CFTimeInterval) {
    uniformValues = makeUniformValues().attribute(
      at: time,
      prev: previousUniformValues,
      animation: animations?.with([.all])
    )
  }

  func build(
    previous: MetalDrawable?,
    device: MTLDevice,
    shaderLibrary: MetalShaderLibrary,
    geometryLibrary: MetalGeometryLibrary,
    surfaceAspect: Float
  ) {
    if let previous = previous as? PlaceLight {
      previousUniformValues = uniformValues
      uniformValues = previous.uniformValues
    }
  }
}
