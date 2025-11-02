//
//  Sphere.swift
//  
//
//  Created by Andrew Zimmer on 2/8/23.
//

import Foundation
import ModelIO
import MetalKit


// MARK: - Sphere

extension MeshFactory {
  func sphere(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> MTKMesh {
    let asset = MDLMesh(sphereWithExtent: .one,
                        segments: vector_uint2(16, 16),
                        inwardNormals: false,
                        geometryType: .triangles,
                        allocator: allocator)
    asset.vertexDescriptor = Vertex.descriptor
    asset.addOrthoTan()
    return try MTKMesh(mesh: asset, device: device)
  }
}

