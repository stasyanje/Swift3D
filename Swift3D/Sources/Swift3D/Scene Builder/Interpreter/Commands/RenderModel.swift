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
  var overrideTextures: Bool
  var animations: [NodeTransition]?
  
  private final class Storage {
    var normalMatrix: float3x3 = float3x3(1)
    var transform: MetalDrawableData.Transform = .identity
    var meshAndTextures: MeshAndTextureStorage?
  }
  
  private let storage = Storage()
}

// MARK: - Render

extension RenderModel {
  var needsRender: Bool { true }

  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    // Depth and Stencil
    encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(.back)

    // Vertices
    var bytes = VertexUniform(modelMatrix: storage.transform, normalMatrix: storage.normalMatrix)
    encoder.setVertexBytes(&bytes, length: MemoryLayout<VertexUniform>.size, index: 1)
    
    shaderPipeline.setupEncoder(encoder: encoder)
    if overrideTextures {
      shaderPipeline.setTextures(encoder: encoder)
    }

    storage.meshAndTextures?.draw(encoder: encoder,
                                  useModelTextures: !overrideTextures)

    encoder.endEncoding()
  }
  
  func update(time: Double) {
    var previous: Storage?
    
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
    if let previous = (previous as? RenderModel)?.storage {
      storage.transform = previous.transform
      storage.normalMatrix = previous.normalMatrix
      storage.meshAndTextures = previous.meshAndTextures
    } else {
      storage.meshAndTextures = .init(device: device)
      storage.meshAndTextures?.build(
        model: model,
        geometryLibrary: geometryLibrary,
        shaderLibrary: shaderLibrary
      )
      storage.transform = transform
    }

    shaderPipeline.build(
      device: device,
      library: shaderLibrary,
      descriptor: storage.meshAndTextures?.vertexDescriptor
    )
  }
}

// MARK: - Model + Texture

typealias StorageMesh = (MTKMesh, MDLMesh)
extension RenderModel {
  fileprivate class MeshAndTextureStorage {
    let device: MTLDevice

    private lazy var textureLoader: MTKTextureLoader = {
      MTKTextureLoader(device: device)
    }()
    private(set) var textures: [String: MTLTexture] = [:]
    private(set) var mesh: [StorageMesh] = []

    var vertexDescriptor: MTLVertexDescriptor? {
      if let modelDesc = mesh.first?.0.vertexDescriptor {
        return MTKMetalVertexDescriptorFromModelIO(modelDesc)
      }
      return nil
    }

    init(device: MTLDevice) {
      self.device = device
    }

    func build(model: Model, geometryLibrary: MetalGeometryLibrary, shaderLibrary: MetalShaderLibrary) {
      do {
        let asset = try model.asset(device: device, allocator: geometryLibrary.allocator)
        asset.loadTextures()

        guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
          fatalError()
        }

        // Add ortho Tan
        mdlMeshes.forEach {
          Model.addOrthoTan(to: $0)
        }

        // Load Meshes
        let mtkMeshes = try mdlMeshes.map { mdlMesh in
          return try MTKMesh(mesh: mdlMesh, device: device)
        }
        self.mesh = zip(mdlMeshes, mtkMeshes).map { ($1, $0) }

        // Load Textures
        let materials = mdlMeshes.flatMap {
          ($0.submeshes as? [MDLSubmesh] ?? []).compactMap { $0.material }
        }
        
        let allSemantics: [MDLMaterialSemantic] = [
          .baseColor,
          .emission,
          .tangentSpaceNormal,
          .roughness,
          .metallic,
          .ambientOcclusion
        ]

        materials.forEach { material in
          allSemantics.forEach { semantic in
            guard let key = material.key(for: semantic) else {
              return
            }
            textures[key] = material.texture(for: semantic, library: shaderLibrary, loader: textureLoader)!
          }
        }
      } catch {
        fatalError("RenderModel Model Failure")
      }
    }

    func draw(encoder: MTLRenderCommandEncoder, useModelTextures: Bool) {
      for storageMesh in mesh {
        for (i, buffer) in storageMesh.0.vertexBuffers.enumerated() {
          encoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: i)
        }

        for (idx, submesh) in storageMesh.0.submeshes.enumerated() {
          if useModelTextures {
            if let sub = storageMesh.1.submeshes?[idx] as? MDLSubmesh,
               let mat = sub.material {
              setTextures(with: mat, encoder: encoder)
            }
          }

          // Draw
          let indexBuffer = submesh.indexBuffer
          encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                        indexCount: submesh.indexCount,
                                        indexType: submesh.indexType,
                                        indexBuffer: indexBuffer.buffer,
                                        indexBufferOffset: indexBuffer.offset)
        }
      }
    }

    func setTextures(with material: MDLMaterial, encoder: MTLRenderCommandEncoder) {
      if let key = material.key(for: .baseColor),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.baseColor.rawValue)
      }

      if let key = material.key(for: .emission),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.emission.rawValue)
      }

      if let key = material.key(for: .tangentSpaceNormal),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.normal.rawValue)
      }

      if let key = material.key(for: .roughness),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.roughness.rawValue)
      }

      if let key = material.key(for: .metallic),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.metalness.rawValue)
      }

      if let key = material.key(for: .ambientOcclusion),
         let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: FragmentTextureIndex.occlusion.rawValue)
      }
    }
  }
}
