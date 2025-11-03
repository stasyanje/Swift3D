//
//  SkyboxShader.swift
//
//
//  Created by Andrew Zimmer on 1/31/23.
//

import Foundation
import Metal
import simd

// MARK: - Init Helper

extension MetalDrawable_Shader where Self == SkyboxShader {
  public static func skybox(_ texture: CubeMap) -> SkyboxShader {
    return .init(texture: texture,
                 storage: SkyboxShader.Storage())
  }
}

// MARK: - Shader

public struct SkyboxShader: MetalDrawable_Shader {
  let texture: CubeMap
  let storage: Storage

  public func build(device: MTLDevice, library: MetalShaderLibrary, descriptor: MTLVertexDescriptor?) {
    // We store and use library directly because it does a lot of the reuse and caching of
    // shaders & textures for us.
    self.storage.library = library
  }

  public func setTextures(encoder: MTLRenderCommandEncoder) {
    if let library = storage.library {
      encoder.setFragmentTexture(texture.mtlTexture(library), index: 0)
    }
  }

  public func setupEncoder(encoder: MTLRenderCommandEncoder) {
    guard let library = storage.library else {
      return
    }
    
    encoder.setRenderPipelineState(
      library.pipeline(
        for: "skybox_vertex",
        fragment: "skybox_fragment",
        vertexDescriptor: nil
      )
    )
  }
}

extension SkyboxShader {
  class Storage {
    fileprivate var library: MetalShaderLibrary?
  }
}
