import Foundation
import UIKit
import Metal
import MetalKit
import simd

struct MeshCollection {
  typealias StorageMesh = (MTKMesh, MDLMesh)
  
  enum Material: Hashable {
    case color(simd_float4)
    case texture(MDLMaterialSemantic, URL?)
  }
  
  let meshes: [StorageMesh]
  let textures: [Material: MTLTexture]
  let vertexDescriptor: MTLVertexDescriptor?
}

final class MeshFactory {
  private let device: MTLDevice
  private let bufferAllocator: MTKMeshBufferAllocator
  private let shaderLibrary: MetalShaderLibrary
  private let textureLoader: MTKTextureLoader
  
  private let supportedSemantics: [MDLMaterialSemantic]
  
  init(device: MTLDevice, shaderLibrary: MetalShaderLibrary) {
    self.device = device
    self.bufferAllocator = MTKMeshBufferAllocator(device: device)
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
  
  func build(from primitive: Primitive) throws -> MTKMesh {
    switch primitive {
    case .capsule: try capsule(device: device, allocator: bufferAllocator)
    case .cone: try cone(device: device, allocator: bufferAllocator)
    case .cube: try cube(device: device, allocator: bufferAllocator)
    case .cylinder: try cylinder(device: device, allocator: bufferAllocator)
    case .octa(let divisions): try octahedron(device: device, allocator: bufferAllocator, divisions: divisions)
    case .sphere: try sphere(device: device, allocator: bufferAllocator)
    case .triangle: try triangle(device: device, allocator: bufferAllocator)
    }
  }

  func build(from url: URL) -> MeshCollection {
    let meshes = try! loadMeshes(from: url)
    
    var textures: [MeshCollection.Material: MTLTexture] = [:]
    
    for (_, mdl) in meshes {
      for material in (mdl.submeshes as! [MDLSubmesh]).compactMap(\.material) {
        for semantic in supportedSemantics {
          if let property = material.property(with: semantic), let key = property.key() {
            textures[key] = property.texture(library: shaderLibrary, loader: textureLoader)!
          }
        }
      }
    }
    
    let descriptor = MTKMetalVertexDescriptorFromModelIO(meshes[0].0.vertexDescriptor)!
    
    return MeshCollection(meshes: meshes, textures: textures, vertexDescriptor: descriptor)
  }

  func draw(collection: MeshCollection, encoder: MTLRenderCommandEncoder, useModelTextures: Bool) {
    for (mtk, mdl) in collection.meshes {
      for (i, buffer) in mtk.vertexBuffers.enumerated() {
        encoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: i)
      }

      for (submeshIndex, submesh) in mtk.submeshes.enumerated() {
        if useModelTextures {
          for (index, semantic) in supportedSemantics.enumerated() {
            let material = (mdl.submeshes![submeshIndex] as! MDLSubmesh).material!
            if let key = material.property(with: semantic)?.key(), let tex = collection.textures[key] {
              encoder.setFragmentTexture(tex, index: index)
            }
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
  
  private func loadMeshes(from url: URL) throws -> [MeshCollection.StorageMesh] {
    assert(MDLAsset.canImportFileExtension(url.pathExtension))
    
    let asset = MDLAsset(url: url, vertexDescriptor: Vertex.descriptor, bufferAllocator: bufferAllocator)
    asset.loadTextures()

    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]

    let mtkMeshes = try mdlMeshes.map { mdlMesh in
      mdlMesh.addOrthoTan()
      return try MTKMesh(mesh: mdlMesh, device: device)
    }
    
    return Array(zip(mtkMeshes, mdlMeshes))
  }
}

private extension MDLMaterialProperty {
  func key() -> MeshCollection.Material? {
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
