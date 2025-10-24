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
  var projection: CameraProjection
  var shaderPipeline: (any MetalDrawable_Shader)?
  var animations: [NodeTransition]?
  
  var viewProjBuffer: MTLBuffer? { storage.viewProjBuffer }
  
  private let storage = PlaceCamera.Storage()
}

// MARK: - Updates

extension PlaceCamera {
  var needsRender: Bool { shaderPipeline != nil }

  // Render our skybox.
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState) {
    guard let shaderPipeline = shaderPipeline else {
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

  var latestViewPoint: float4x4 { storage.view }
  
  func update(time: CFTimeInterval) {
    var previous: PlaceCamera.Storage? // TODO: restore passing previous
    assert(previous == nil)

    let view = transform.attribute(
      at: time,
      prev: previous?.view,
      animation: animations?.with([.all])
    )

    let targetProj = projection.matrix(aspect: storage.surfaceAspect)
    let projection = targetProj.attribute(
      at: time,
      prev: previous?.projection,
      animation: animations?.with([.all])
    )
    
    storage.updateBuffers(transform: view, projection: projection)
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
    
    func updateBuffers(transform: MetalDrawableData.Transform, projection: float4x4) {
      // Update matrices
      self.view = transform
      let view = view.inverse
      self.projection = projection
      
      // Update uniform
      let vpUniform = ViewProjectionUniform(projectionMatrix: projection, viewMatrix: view)
      self.viewProjBuffer?.contents().storeBytes(of: vpUniform, as: ViewProjectionUniform.self)
      
      // Skybox inverse view matrix.
      var viewDirectionMatrix = view
      viewDirectionMatrix.columns.3 = SIMD4<Float>(0, 0, 0, 1)
      let clipToViewDirectionTransform = (projection * viewDirectionMatrix).inverse
      self.skyboxInverseView = clipToViewDirectionTransform
    }
  }
}
