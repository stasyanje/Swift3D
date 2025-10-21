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
  
  let storage: PlaceCamera.Storage
}

// MARK: - Updates

extension PlaceCamera {
  var needsRender: Bool { shaderPipeline != nil }

  // Render our skybox.
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?) {
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

  var latestViewPoint: float4x4 {
    self.storage.view.value
  }
}

// MARK: Storage
extension PlaceCamera {
  class Storage: MetalDrawable_Storage {
    private(set) var surfaceAspect: Float = 1
    private(set) var viewProjBuffer: MTLBuffer?

    private(set) var view: MetalDrawableData.Transform = .identity
    private(set) var projection: float4x4?
    var skyboxInverseView: float4x4 = .identity
  }
}

extension PlaceCamera.Storage {
  private func updateBuffers(transform: MetalDrawableData.Transform, projection: float4x4) {
    // Update matrices
    self.view = .init(value: transform.value)
    let view = view.value.inverse
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

  func update(time: CFTimeInterval, command: (any MetalDrawable), previous: (any MetalDrawable_Storage)?) {
    let previous = previous as? Self
    guard let command = command as? PlaceCamera else {
      fatalError()
    }

    let view = attribute(at: time,
                         cur: command.transform,
                         prev: previous?.view,
                         animation: command.animations?.with([.all]))

    let targetProj = command.projection.matrix(aspect: self.surfaceAspect)
    let projection = attribute(at: time,
                               cur: targetProj,
                               prev: previous?.projection,
                               animation: command.animations?.with([.all]))

    updateBuffers(transform: view, projection: projection)
  }
  
  func build(_ command: (any MetalDrawable),
               previous: (any MetalDrawable_Storage)?,
               device: MTLDevice, 
               shaderLibrary: MetalShaderLibrary,
               geometryLibrary: MetalGeometryLibrary,
               surfaceAspect: Float) {
    let previous = previous as? Self
    guard let command = command as? PlaceCamera else {
      fatalError()
    }

    self.surfaceAspect = surfaceAspect

    // Build the Pipeline
    command.shaderPipeline?.build(device: device, library: shaderLibrary, descriptor: nil)
    
    // Re-use previous buffers if they are the right size / data and
    // copy data from previous storage for animations.
    if let previous = previous {
      viewProjBuffer = previous.viewProjBuffer
      view = previous.view
      projection = previous.projection
      skyboxInverseView = previous.skyboxInverseView
    } else {
      // Make the buffers / data from scratch!
      viewProjBuffer = device.makeBuffer(length: MemoryLayout<ViewProjectionUniform>.size)
      updateBuffers(
        transform: command.transform,
        projection: command.projection.matrix(aspect: surfaceAspect)
      )
    }
  }
}
