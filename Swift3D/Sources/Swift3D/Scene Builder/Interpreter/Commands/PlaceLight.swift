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

struct PlaceLight: MetalDrawable {
  var id: String
  var transform: MetalDrawableData.Transform
  
  let direction: LightDirection
  var color: simd_float4
  
  var animations: [NodeTransition]?
  
  private final class Storage {
    var uniformValues: Light?
  }

  private let storage = PlaceLight.Storage()
}

// MARK: - Updates

extension PlaceLight {  
  var needsRender: Bool { false }
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?) {
    fatalError()
  }
  
  var uniformValues: Light {
    let position = switch direction {
    case .ambient:
      simd_float4(.zero, Float(direction.rawValue))
    case .directional:
      simd_float4(transform.value.rotation.act(.back), Float(direction.rawValue))
    case .point:
      simd_float4(transform.value.translation, Float(direction.rawValue))
    }
    
    return Light(position: position, color: color)
  }
  
  func update(time: CFTimeInterval) {
    var previous: Storage? // TODO:
    
    storage.uniformValues = uniformValues.attribute(
      at: time,
      prev: previous?.uniformValues,
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
    if let previous = (previous as? PlaceLight)?.storage {
      storage.uniformValues = previous.uniformValues
    }
  }
}
