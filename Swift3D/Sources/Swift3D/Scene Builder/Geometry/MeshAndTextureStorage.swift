//
//  MeshAndTextureStorage.swift
//  Swift3D
//
//  Created by Stanislav Kaliuzhnyi on 10/31/25.
//


import Foundation
import UIKit
import Metal
import MetalKit
import simd

final class MeshAndTextureStorage {
  private typealias StorageMesh = (MTKMesh, MDLMesh)
  
  private let device: MTLDevice
  private let supportedSemantics: [MDLMaterialSemantic]

  private lazy var textureLoader = MTKTextureLoader(device: device)
  
  private var textures: [String: MTLTexture] = [:]
  private var meshes: [StorageMesh] = []

  var vertexDescriptor: MTLVertexDescriptor? {
    if let modelDesc = meshes.first?.0.vertexDescriptor {
      return MTKMetalVertexDescriptorFromModelIO(modelDesc)
    }
    return nil
  }
  
  init(device: MTLDevice) {
    self.device = device
    
    self.supportedSemantics = [
      .baseColor,
      .tangentSpaceNormal,
      .emission,
      .metallic,
      .roughness,
      .ambientOcclusion
    ]
  }

  func build(model: Model, geometryLibrary: MetalGeometryLibrary, shaderLibrary: MetalShaderLibrary) {
    do {
      meshes = try loadMeshes(model: model, geometryLibrary: geometryLibrary)
    } catch {
      fatalError("RenderModel Model Failure \(String(describing: error))")
    }
    
    loadTextures(shaderLibrary: shaderLibrary)
  }

  func draw(encoder: MTLRenderCommandEncoder, useModelTextures: Bool) {
    for storageMesh in meshes {
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
        encoder.drawIndexedPrimitives(
          type: submesh.primitiveType,
          indexCount: submesh.indexCount,
          indexType: submesh.indexType,
          indexBuffer: indexBuffer.buffer,
          indexBufferOffset: indexBuffer.offset
        )
      }
    }
  }
  
  // MARK: - Private
  
  private func loadMeshes(model: Model, geometryLibrary: MetalGeometryLibrary) throws -> [StorageMesh] {
    let asset = try model.asset(device: device, allocator: geometryLibrary.allocator)
    asset.loadTextures()

    guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
      throw NSError(domain: "MDLAsset.childObjects", code: -1)
    }

    // Load Meshes
    let mtkMeshes = try mdlMeshes.map { mdlMesh in
      Model.addOrthoTan(to: mdlMesh)
      return try MTKMesh(mesh: mdlMesh, device: device)
    }
    
    return Array(zip(mtkMeshes, mdlMeshes))
  }
  
  private func loadTextures(shaderLibrary: MetalShaderLibrary) {
    // Load Textures
    let materials = meshes.flatMap { _, mdl -> [MDLMaterial] in
      guard let submeshes = mdl.submeshes as? [MDLSubmesh] else {
        assertionFailure("unexpected type: \(String(describing: mdl.submeshes))")
        return []
      }
      return submeshes.compactMap(\.material)
    }

    materials.forEach { material in
      supportedSemantics.forEach { semantic in
        guard let key = material.key(for: semantic) else {
          return
        }
        textures[key] = material.texture(for: semantic, library: shaderLibrary, loader: textureLoader)!
      }
    }
  }
  
  private func setTextures(with material: MDLMaterial, encoder: MTLRenderCommandEncoder) {
    supportedSemantics.enumerated().forEach { index, semantic in
      guard let key = material.key(for: semantic), let tex = textures[key] else {
        return
      }
      encoder.setFragmentTexture(tex, index: index)
    }
  }
}
