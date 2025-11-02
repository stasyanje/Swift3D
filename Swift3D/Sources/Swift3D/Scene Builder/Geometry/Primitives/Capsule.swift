//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import ModelIO
import MetalKit

extension MeshFactory {
  func capsule(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> MTKMesh {
    let asset = MDLMesh(capsuleWithExtent: simd_float3(x: 1, y: 3, z: 1),
                        cylinderSegments: vector_uint2(16, 16),
                        hemisphereSegments: 16,
                        inwardNormals: false,
                        geometryType: .triangles,
                        allocator: allocator)
    asset.vertexDescriptor = Vertex.descriptor
    asset.addOrthoTan()
    return try MTKMesh(mesh: asset, device: device)
  }
}
