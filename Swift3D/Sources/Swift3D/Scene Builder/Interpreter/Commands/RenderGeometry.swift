//
//  NodeRenderCommand.swift
//  
//
//  Created by Andrew Zimmer on 1/26/23.
//

import Foundation
import UIKit
import Metal
import MetalKit
import simd

protocol HasShaderPipeline {
  var shaderPipeline: MetalDrawable_Shader { get set }
}

// MARK: - NodeRenderCommand

final class RenderGeometry: MetalDrawable, HasShaderPipeline {
  var id: String
  var transform: MetalDrawableData.Transform
  var shaderPipeline: MetalDrawable_Shader
  let renderType: MetalDrawableData.RenderType?
  var animations: [NodeTransition]?
  
  let geometry: MetalDrawable_Geometry
  
  let cullBackfaces: Bool
  
  private struct Storage {
    var transform: MetalDrawableData.Transform
    var previousTransform: MetalDrawableData.Transform?
    var normalMatrix: float3x3 = float3x3(1)
    var mesh: MTKMesh?
  }
  
  private var storage: Storage

  init(
    id: String,
    transform: MetalDrawableData.Transform,
    geometry: any MetalDrawable_Geometry,
    shaderPipeline: MetalDrawable_Shader,
    renderType: MetalDrawableData.RenderType?,
    animations: [NodeTransition]?,
    cullBackfaces: Bool
  ) {
    self.id = id
    self.transform = transform
    self.geometry = geometry
    self.shaderPipeline = shaderPipeline
    self.renderType = renderType
    self.animations = animations
    self.cullBackfaces = cullBackfaces

    self.storage = Storage(transform: transform)
    // Initialize storage with current transform
    self.storage.transform = transform
  }
}

// MARK: - Render

extension RenderGeometry {    
  var needsRender: Bool { true }
  
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    // Depth and Stencil
    encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(cullBackfaces ? .back : .none)    
    
    // Vertices
    var bytes = VertexUniform(
      modelMatrix: storage.transform,
      normalMatrix: storage.normalMatrix
    )
    encoder.setVertexBytes(&bytes, length: MemoryLayout<VertexUniform>.size, index: 1)
    
    // Shaders and Uniforms
    self.shaderPipeline.setupEncoder(encoder: encoder)
    self.shaderPipeline.setTextures(encoder: encoder)

    // Draw Meshes
    if let mesh = storage.mesh {
      for (i, buffer) in mesh.vertexBuffers.enumerated() {
        encoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: i)
      }

      for submesh in mesh.submeshes {
        let indexBuffer = submesh.indexBuffer
        encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                      indexCount: submesh.indexCount,
                                      indexType: submesh.indexType,
                                      indexBuffer: indexBuffer.buffer,
                                      indexBufferOffset: indexBuffer.offset)
      }
    }
    
    encoder.endEncoding()
  }
  
  func update(time: CFTimeInterval) {
    storage.transform = LerpableTransform(value: transform).attribute(
      at: time,
      prev: storage.previousTransform.flatMap(LerpableTransform.init(value:)),
      animation: animations?.with([.all])
    ).value
  }
  
  func build(
    previous: MetalDrawable?,
    device: MTLDevice,
    shaderLibrary: MetalShaderLibrary,
    geometryLibrary: MetalGeometryLibrary,
    surfaceAspect: Float
  ) {
    storage.previousTransform = storage.transform

    if let previous = (previous as? RenderGeometry)?.storage {
      storage.transform = previous.transform
      storage.mesh = previous.mesh
    } else {
      storage.transform = transform
      storage.mesh = try! geometryLibrary.cachedMesh(geometry)
    }
    
    // set up our shader pipeline
    var vertexDescriptor: MTLVertexDescriptor?
    if let modelDescriptor = storage.mesh?.vertexDescriptor {
      vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(modelDescriptor)
    }

    shaderPipeline.build(device: device, library: shaderLibrary, descriptor: vertexDescriptor)
  }
}

