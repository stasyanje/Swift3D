//
//  Cone.swift
//  
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import ModelIO
import MetalKit

extension MeshFactory {
  func cone(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> MTKMesh {
    let asset = MDLMesh(coneWithExtent: .one * 2,
                        segments: vector_uint2(16, 16),
                        inwardNormals: false,
                        cap: true,
                        geometryType: .triangles,
                        allocator: allocator)
    asset.vertexDescriptor = Vertex.descriptor
    asset.addOrthoTan()
    return try MTKMesh(mesh: asset, device: device)
  }
}
