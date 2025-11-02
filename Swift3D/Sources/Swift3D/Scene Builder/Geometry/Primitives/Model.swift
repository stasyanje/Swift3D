//
//  Model.swift
//  
//
//  Created by Andrew Zimmer on 2/7/23.
//

import Foundation
import ModelIO
import MetalKit

private enum ModelLoadError: Error {
  case unsupportedType
  case noMeshes
  case noTextures
}

struct Model: MetalDrawable_Geometry {
  let url: URL
  var cacheKey: String { "some_model" }

  func get(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> MTKMesh {
    fatalError("Not used, check RenderModel for custom loading logic")
  }

  func asset(allocator: MTKMeshBufferAllocator) throws -> MDLAsset {
    guard MDLAsset.canImportFileExtension(url.pathExtension) else {
      throw ModelLoadError.unsupportedType
    }

    return MDLAsset(url: url, vertexDescriptor: Vertex.descriptor, bufferAllocator: allocator)
  }
}
