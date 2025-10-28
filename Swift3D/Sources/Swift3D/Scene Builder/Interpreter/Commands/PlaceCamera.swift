//
//  PlaceCamera.swift
//  
//
//  Created by Andrew Zimmer on 1/26/23.
//

import Foundation
import UIKit
import Metal
import simd

// MARK: - Buffer Uniforms

struct ViewProjectionUniform {
  let projectionMatrix: float4x4
  let viewMatrix: float4x4
}

// MARK: - Command

struct PlaceCamera: MetalDrawable {
  var id: String
  var transform: MetalDrawableData.Transform
  var animations: [NodeTransition]?
  var needsRender: Bool { shaderPipeline != nil }

  let shaderPipeline: MetalDrawable_Shader?
  var projection: CameraProjection
  var viewProjBuffer: MTLBuffer? { storage.viewProjBuffer }
  
  private let storage = PlaceCamera.Storage()
  
  // MARK: - MetalDrawable

  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    guard let shaderPipeline else {
      fatalError()
    }

    // encoder.setDepthStencilState(depthStencil)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setCullMode(.none)

    // Shaders and Uniforms
    shaderPipeline.setupEncoder(encoder: encoder)
    shaderPipeline.setTextures(encoder: encoder)
    
    encoder.setFragmentBytes(&storage.skyboxInverseView, length: MemoryLayout<float4x4>.size, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.endEncoding()
  }

  func update(time: CFTimeInterval) {
    storage.updateBuffers(
      transform: transform.attribute(
        at: time,
        prev: storage.previousView,
        animation: animations?.with([.all])
      ),
      projection: projection.matrix(aspect: storage.surfaceAspect).attribute(
        at: time,
        prev: storage.previousProjection,
        animation: animations?.with([.all])
      )
    )
  }
  
  func build(
    previous: MetalDrawable?,
    device: MTLDevice,
    shaderLibrary: MetalShaderLibrary,
    geometryLibrary: MetalGeometryLibrary,
    surfaceAspect: Float
  ) {
    storage.surfaceAspect = surfaceAspect

    // Build the Pipeline
    shaderPipeline?.build(device: device, library: shaderLibrary, descriptor: nil)
    
    // Re-use previous buffers if they are the right size / data and
    // copy data from previous storage for animations.
    if let previous = previous as? Self {
      storage.viewProjBuffer = previous.storage.viewProjBuffer
      storage.view = previous.storage.view
      storage.projection = previous.storage.projection
      storage.skyboxInverseView = previous.storage.skyboxInverseView
    } else {
      // Make the buffers / data from scratch!
      storage.viewProjBuffer = device.makeBuffer(length: MemoryLayout<ViewProjectionUniform>.size)
      storage.updateBuffers(
        transform: transform,
        projection: projection.matrix(aspect: surfaceAspect)
      )
    }
  }
}

// MARK: Storage
private extension PlaceCamera {
  final class Storage {
    var surfaceAspect: Float = 1
    var viewProjBuffer: MTLBuffer?

    var view: MetalDrawableData.Transform = .identity
    var projection: float4x4?
    var skyboxInverseView: float4x4 = .identity
    
    var previousView: float4x4?
    var previousProjection: float4x4?
    
    func updateBuffers(transform: MetalDrawableData.Transform, projection: float4x4) {
      previousView = self.view
      previousProjection = self.projection
      
      // Update matrices
      self.view = transform
      let view = view.inverse
      self.projection = projection
      
      // Update uniform
      viewProjBuffer?.contents().storeBytes(
        of: ViewProjectionUniform(projectionMatrix: projection, viewMatrix: view),
        as: ViewProjectionUniform.self
      )
      
      // Skybox inverse view matrix.
      var viewDirectionMatrix = view
      viewDirectionMatrix.columns.3 = SIMD4<Float>(0, 0, 0, 1)
      let clipToViewDirectionTransform = (projection * viewDirectionMatrix).inverse
      self.skyboxInverseView = clipToViewDirectionTransform
    }
  }
}
