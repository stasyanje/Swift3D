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

protocol HasShaderPipeline {
  var shaderPipeline: MetalDrawable_Shader { get set }
}

public enum Primitive: Hashable {
  case capsule
  case cone
  case cube
  case cylinder
  case octa(divisions: Int)
  case sphere
  case triangle
}

public enum Renderable {
  case primitive(Primitive)
  case url(URL, overrideTextures: Bool = false)
}

struct RenderModel: MetalDrawable, HasShaderPipeline {
  var id: String
  var transform: MetalTransform
  var shaderPipeline: MetalDrawable_Shader
  var animations: [NodeTransition]?
  
  let model: Renderable
  
  private final class Storage {
    var transform: MetalTransform = .identity
    var previousTransform: MetalTransform?
    var normalMatrix: float3x3 = float3x3(1)
    var meshFactory: MeshFactory?
    
    var primitiveMesh: MTKMesh?
    var meshCollection: MeshCollection?
  }
  
  private let storage = Storage()
  
  // MARK: - MetalDrawable
  
  func update(time: Double) {
    switch model {
    case .primitive:
      storage.transform = LerpableTransform(value: transform).attribute(
        at: time,
        prev: storage.previousTransform.flatMap(LerpableTransform.init(value:)),
        animation: animations?.with([.all])
      ).value
    case .url:
      storage.transform = transform.attribute(
        at: time,
        prev: storage.previousTransform,
        animation: animations?.with([.all])
      )
    }
  }
  
  func build(
    previous: MetalDrawable?,
    device: MTLDevice,
    shaderLibrary: MetalShaderLibrary,
    surfaceAspect: Float
  ) {
    storage.previousTransform = storage.transform
    
    if let previous = (previous as? RenderModel)?.storage {
      storage.transform = previous.transform
      storage.normalMatrix = previous.normalMatrix
      storage.meshFactory = previous.meshFactory
      storage.primitiveMesh = previous.primitiveMesh
      storage.meshCollection = previous.meshCollection
    } else {
      let meshFactory = MeshFactory(device: device, shaderLibrary: shaderLibrary)
      switch model {
      case .primitive(let primitive):
        storage.primitiveMesh = try! meshFactory.build(from: primitive)
      case .url(let url, _):
        storage.meshCollection = meshFactory.build(from: url)
      }
      storage.meshFactory = meshFactory
      storage.transform = transform
    }
    
    shaderPipeline.build(
      device: device,
      library: shaderLibrary,
      descriptor: storage.meshCollection?.vertexDescriptor ?? MTKMetalVertexDescriptorFromModelIO(storage.primitiveMesh!.vertexDescriptor)!
    )
  }
  
  var needsRender: Bool { true }
  
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    if let primitiveMesh = storage.primitiveMesh {
      render(primitive: primitiveMesh, encoder: encoder, depthStencil: depthStencil)
    }
    
    if let meshCollection = storage.meshCollection {
      render(meshCollection: meshCollection, encoder: encoder, depthStencil: depthStencil)
    }
  }
  
  private func render(
    primitive mesh: MTKMesh,
    encoder: MTLRenderCommandEncoder,
    depthStencil: MTLDepthStencilState
  ) {
    // Depth and Stencil
    encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(.none)
    
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
    
    encoder.endEncoding()
  }
  
  private func render(
    meshCollection: MeshCollection,
    encoder: MTLRenderCommandEncoder,
    depthStencil: MTLDepthStencilState
  ) {
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
    
    let overrideTextures = switch model {
    case .primitive: false
    case .url(_, let overrideTextures): overrideTextures
    }
    
    if overrideTextures {
      shaderPipeline.setTextures(encoder: encoder)
    }
    
    storage.meshFactory?.draw(
      collection: storage.meshCollection!,
      encoder: encoder,
      useModelTextures: !overrideTextures
    )
    
    encoder.endEncoding()
  }
}
