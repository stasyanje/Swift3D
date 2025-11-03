//
//  ShaderPipeline.swift
//  
//
//  Created by Andrew Zimmer on 1/27/23.
//

import Foundation
import Metal
import SwiftUI
import UIKit
import simd

// MARK: - Shader

public protocol MetalDrawable_Shader {
  func setupEncoder(encoder: MTLRenderCommandEncoder)
  func setTextures(encoder: MTLRenderCommandEncoder)

  func build(device: MTLDevice, library: MetalShaderLibrary, descriptor: MTLVertexDescriptor?)
}

// MARK: - Vertex Uniform

struct VertexUniform {
  let modelMatrix: float4x4
  let normalMatrix: float3x3
}

// MARK: - Textures

public protocol MetalDrawable_Texture {
  func mtlTexture(_ library: MetalShaderLibrary) -> MTLTexture
}

extension Color: MetalDrawable_Texture {
  public func mtlTexture(_ library: MetalShaderLibrary) -> MTLTexture {
    library.texture(color: components)
  }
}

extension UIImage: MetalDrawable_Texture {
  public func mtlTexture(_ library: MetalShaderLibrary) -> MTLTexture {
    library.texture(image: cgImage!)
  }
}

public struct CubeMap: MetalDrawable_Texture {
  public let imageName: String
  
  public init(imageName: String) {
    self.imageName = imageName
  }

  public func mtlTexture(_ library: MetalShaderLibrary) -> MTLTexture {
    library.cubeTexture(image: UIImage(named: imageName)!)
  }
}

