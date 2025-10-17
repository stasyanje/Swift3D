//
//  MetalGeometryLibrary.swift
//  
//
//  Created by Andrew Zimmer on 2/7/23.
//

import Foundation
import Metal
import MetalKit
import ModelIO

public class MetalGeometryLibrary {
  private let device: MTLDevice
  private(set) lazy var allocator = MTKMeshBufferAllocator(device: device)
  // TODO: Limit the size of this fella.
  private var mdlModels: [String: MTKMesh] = [:]

  init(device: MTLDevice) {
    self.device = device
  }

  func cachedMesh(_ geometry: MetalDrawable_Geometry) throws -> MTKMesh {
    if let asset = mdlModels[geometry.cacheKey] {
      return asset
    }
    
    let asset = try geometry.get(device: device, allocator: allocator)
    mdlModels[geometry.cacheKey] = asset
    return asset
  }
}
