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

struct RenderGeometry: MetalDrawable, HasShaderPipeline {
  var id: String
  var transform: MetalDrawableData.Transform
  let geometry: any MetalDrawable_Geometry
  var shaderPipeline: MetalDrawable_Shader
  let renderType: MetalDrawableData.RenderType?
  var animations: [NodeTransition]?
  let cullBackfaces: Bool
  
  private final class Storage {
    var mesh: MTKMesh?

    var normalMatrix: float3x3 = float3x3(1)
    var transform: MetalDrawableData.Transform = .identity
  }
  
  private let storage = RenderGeometry.Storage()
}

// MARK: - Render

extension RenderGeometry {    
  var needsRender: Bool { true }
  
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?) {
    // Depth and Stencil
    encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(cullBackfaces ? .back : .none)    
    
    // Vertices
    var bytes = VertexUniform(modelMatrix: storage.transform.value, normalMatrix: storage.normalMatrix)
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
    var previous: Storage? // TODO:
    assert(previous == nil)
    
    storage.transform = transform.attribute(
      at: time,
      prev: previous?.transform,
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
    let previous = (previous as? RenderGeometry)?.storage

    if let previous = previous {
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

