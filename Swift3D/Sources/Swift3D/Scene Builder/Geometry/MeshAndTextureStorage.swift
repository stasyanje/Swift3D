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
  private let geometryLibrary: MetalGeometryLibrary
  private let shaderLibrary: MetalShaderLibrary
  private let textureLoader: MTKTextureLoader
  
  private let supportedSemantics: [MDLMaterialSemantic]
  
  private var textures: [MDLMaterialProperty.PropertyKey: MTLTexture] = [:]
  private var meshes: [StorageMesh] = []

  var vertexDescriptor: MTLVertexDescriptor? {
    if let modelDesc = meshes.first?.0.vertexDescriptor {
      return MTKMetalVertexDescriptorFromModelIO(modelDesc)
    }
    return nil
  }
  
  init(device: MTLDevice, geometryLibrary: MetalGeometryLibrary, shaderLibrary: MetalShaderLibrary) {
    self.device = device
    self.geometryLibrary = geometryLibrary
    self.shaderLibrary = shaderLibrary
    self.textureLoader = MTKTextureLoader(device: device)
    
    self.supportedSemantics = [
      .baseColor,
      .tangentSpaceNormal,
      .emission,
      .metallic,
      .roughness,
      .ambientOcclusion
    ]
  }

  func build(model: Model) {
    meshes = try! loadMeshes(model: model)
    loadTextures()
  }

  func draw(encoder: MTLRenderCommandEncoder, useModelTextures: Bool) {
    for (mtk, mdl) in meshes {
      for (i, buffer) in mtk.vertexBuffers.enumerated() {
        encoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: i)
      }

      for (idx, submesh) in mtk.submeshes.enumerated() {
        if useModelTextures {
          setTextures(with: (mdl.submeshes![idx] as! MDLSubmesh).material!, encoder: encoder)
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
  
  private func loadMeshes(model: Model) throws -> [StorageMesh] {
    let asset = try model.asset(allocator: geometryLibrary.allocator)
    asset.loadTextures()

    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]

    let mtkMeshes = try mdlMeshes.map { mdlMesh in
      Model.addOrthoTan(to: mdlMesh)
      return try MTKMesh(mesh: mdlMesh, device: device)
    }
    
    return Array(zip(mtkMeshes, mdlMeshes))
  }
  
  private func loadTextures() {
    for (_, mdl) in meshes {
      for material in (mdl.submeshes as! [MDLSubmesh]).compactMap(\.material) {
        for semantic in supportedSemantics {
          if let property = material.property(with: semantic), let key = property.key() {
            textures[key] = property.texture(library: shaderLibrary, loader: textureLoader)!
          }
        }
      }
    }
  }
  
  private func setTextures(with material: MDLMaterial, encoder: MTLRenderCommandEncoder) {
    for (index, semantic) in supportedSemantics.enumerated() {
      if let key = material.property(with: semantic)?.key(), let tex = textures[key] {
        encoder.setFragmentTexture(tex, index: index)
      }
    }
  }
}

private extension MDLMaterialProperty {
  enum PropertyKey: Hashable {
    case color(simd_float4)
    case texture(MDLMaterialSemantic, URL?)
  }
  
  func key() -> PropertyKey? {
    switch type {
    case .float3, .float4, .color:
      return .color(color())
      
    case .texture:
      return .texture(semantic, urlValue!)
      
    default:
      return nil
    }
  }

  func texture(library: MetalShaderLibrary, loader: MTKTextureLoader) -> MTLTexture? {
    switch type {
    case .float3, .float4, .color:
      return library.texture(color: color())

    case .texture:
      return try! loader.newTexture(texture: textureSamplerValue!.texture!, options: [
        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
        .textureStorageMode : MTLStorageMode.private.rawValue,
        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue
      ])
    default:
      return nil
    }
  }

  private func color() -> simd_float4 {
    switch type {
    case .float4:
      return simd_float4(float3Value, 1)
    case .float3:
      return float4Value
    case .color:
      let color = color ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
      if let components = color.components, color.numberOfComponents == 4 {
        return simd_float4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
      }
    default:
      break
    }

    return .zero
  }
}
