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

  init(device: MTLDevice) {
    self.device = device
  }
}
