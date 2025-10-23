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

  let storage: PlaceLight.Storage
}

// MARK: - Updates

extension PlaceLight {  
  var needsRender: Bool { false }
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?) {
    fatalError()
  }
  
  func update(time: CFTimeInterval) {
    storage.update(time: time, command: self, previous: nil)
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
}

// MARK: Storage

extension PlaceLight {
  class Storage: MetalDrawable_Storage {
    private(set) var uniformValues: Light?
  }
}

extension PlaceLight.Storage {
  func update(
    time: CFTimeInterval,
    command: any MetalDrawable,
    previous: (any MetalDrawable_Storage)?
  ) {
    guard let command = command as? PlaceLight else {
      fatalError()
    }

    uniformValues = command.uniformValues.attribute(
      at: time,
      prev: (previous as? PlaceLight.Storage)?.uniformValues,
      animation: command.animations?.with([.all])
    )
  }

  func build(_ command: (any MetalDrawable),
               previous: (any MetalDrawable_Storage)?,
               device: MTLDevice, 
               shaderLibrary: MetalShaderLibrary,
               geometryLibrary: MetalGeometryLibrary,
               surfaceAspect: Float) {
    if let previous = previous as? PlaceLight.Storage {
      self.uniformValues = previous.uniformValues
    }
  }
}
