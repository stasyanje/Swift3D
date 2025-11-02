//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/20/23.
//

import Foundation
import UIKit
import Metal
import MetalKit
import simd

// MARK: - NodeRenderCommand

struct RenderModel: MetalDrawable, HasShaderPipeline {
  var id: String
  var transform: MetalDrawableData.Transform
  let model: Model
  var shaderPipeline: MetalDrawable_Shader
  var needsRender: Bool { true }
  
  var overrideTextures: Bool
  var animations: [NodeTransition]?
  
  private final class Storage {
    var transform: MetalDrawableData.Transform = .identity
    var previousTransform: MetalDrawableData.Transform?
    var normalMatrix: float3x3 = float3x3(1)
    var meshAndTextures: MeshAndTextureStorage?
  }
  
  private let storage = Storage()
  
  // MARK: - MetalDrawable
  
  func update(time: Double) {
    storage.transform = transform.attribute(
      at: time,
      prev: storage.previousTransform,
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
    storage.previousTransform = storage.transform
    
    if let previous = (previous as? RenderModel)?.storage {
      storage.transform = previous.transform
      storage.normalMatrix = previous.normalMatrix
      storage.meshAndTextures = previous.meshAndTextures
    } else {
      storage.meshAndTextures = .init(device: device, geometryLibrary: geometryLibrary, shaderLibrary: shaderLibrary)
      storage.meshAndTextures?.build(model: model)
      storage.transform = transform
    }
    
    shaderPipeline.build(
      device: device,
      library: shaderLibrary,
      descriptor: storage.meshAndTextures?.vertexDescriptor
    )
  }
  
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    // Depth and Stencil
    encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(.back)
    
    // Vertices
    var bytes = VertexUniform(
      modelMatrix: storage.transform,
      normalMatrix: storage.normalMatrix
    )
    encoder.setVertexBytes(&bytes, length: MemoryLayout<VertexUniform>.size, index: 1)
    
    shaderPipeline.setupEncoder(encoder: encoder)
    if overrideTextures {
      shaderPipeline.setTextures(encoder: encoder)
    }
    
    storage.meshAndTextures?.draw(
      encoder: encoder,
      useModelTextures: !overrideTextures
    )
    
    encoder.endEncoding()
  }
}
