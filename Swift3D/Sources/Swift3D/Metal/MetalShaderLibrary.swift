//
//  MetalShaderLibrary.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import Foundation
import Metal
import MetalKit
import UIKit
import simd

public final class MetalShaderLibrary {
  // TODO: Limit the size of this fella.
  private var pipelines: [String: MTLRenderPipelineState] = [:]
  private var colorTextures: [simd_float4: MTLTexture] = [:]
  private var imageTextures: [CGImage: MTLTexture] = [:]
  private var cubeTextures: [UIImage: MTLTexture] = [:]

  private let device: MTLDevice
  private let library: MTLLibrary
  private let bufferFactory: MetalBufferFactory

  init(device: MTLDevice, bufferFactory: MetalBufferFactory) throws {
    self.device = device
    self.library = try device.makeDefaultLibrary(bundle: Bundle.module)
    self.bufferFactory = bufferFactory
  }
  
  func pipeline(for vertex: String, fragment: String, vertexDescriptor: MTLVertexDescriptor? = nil) -> MTLRenderPipelineState {
    let key = "\(vertex).\(fragment).\(String(describing:vertexDescriptor))"
    if let pipe = pipelines[key] {
      return pipe
    }
    
    let vertexProgram = library.makeFunction(name: vertex)
    let fragmentProgram = library.makeFunction(name: fragment)

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.vertexDescriptor = vertexDescriptor

    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
    
    do {
      let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
      pipelines[key] = pipelineState
      return pipelineState
    } catch {
      print("Shader Compile Error: \(error)")
      fatalError()
    }
  }
  
  func texture(color: simd_float4) -> MTLTexture {
    if let tex = colorTextures[color] {
      return tex
    }
    
    let texture = bufferFactory.texture(from: color)
    colorTextures[color] = texture
    return texture
  }
  
  func texture(image: CGImage) -> MTLTexture {
    if let tex = imageTextures[image] {
      return tex
    }
    
    let texture = bufferFactory.texture(from: image)
    imageTextures[image] = texture
    return texture    
  }

  func cubeTexture(image: UIImage) -> MTLTexture {
    if let tex = cubeTextures[image] {
      return tex
    }

    let texture = bufferFactory.cubeTexture(image: image)
    cubeTextures[image] = texture
    return texture
  }
}
