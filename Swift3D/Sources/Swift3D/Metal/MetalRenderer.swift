import Foundation
import UIKit
import Metal
import simd

// MARK: - Renderer

public class MetalRenderer {
  public enum Error: Swift.Error {
    case commandQueueInit
    case sfuBufferInit
    case commandBufferInit
    case encoderInit(any MetalDrawable)
  }
  
  private let commandQueue: MTLCommandQueue
  let metalDevice: MTLDevice
  let depthStencilState: MTLDepthStencilState?
  let standardFragmentUniformBuffer: MTLBuffer
  
  private lazy var defaultProjViewBuffer: MTLBuffer? = {
    metalDevice.makeBuffer(length: MemoryLayout<ViewProjectionUniform>.size).flatMap { buff in
      buff.contents().storeBytes(
        of: ViewProjectionUniform(projectionMatrix: float4x4.identity, viewMatrix: float4x4.identity),
        as: ViewProjectionUniform.self
      )
      return buff
    }
  }()
  
  public init(device: MTLDevice) throws(Error) {
    guard let cq = device.makeCommandQueue() else {
      throw .commandQueueInit
    }
    
    guard let buff = device.makeBuffer(length: MemoryLayout<StandardFragmentUniform>.size) else {
      throw .sfuBufferInit
    }
    
    commandQueue = cq
    metalDevice = device
    standardFragmentUniformBuffer = buff

    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: descriptor)
  }
  
  func render(
    _ time: CFTimeInterval,
    layerDrawable: CAMetalDrawable,
    depthTexture: MTLTexture,
    commands: [CommandAndPrevious]
  ) throws(Error) {
    guard let buffer = commandQueue.makeCommandBuffer() else {
      throw .commandBufferInit
    }

    // Clear the textures
    clearPass(buffer: buffer, layerDrawable: layerDrawable, depthTexture: depthTexture)
    
    // Render Command Pass
    let renderPassDescriptor = renderPassDescriptor(buffer: buffer, layerDrawable: layerDrawable, depthTexture: depthTexture)

    // Light Setup
    let lightsData = commands.compactMap { ($0.0 as? PlaceLight)?.uniformValues }

    // Camera and Fragment uniforms setup
    let viewProjBuffer = viewProjectionBuffer(from: commands)
    var fragmentUniform = standardFragmentUniform(from: commands, lightCount: lightsData.count)

    for (command, _) in commands where command.needsRender {
      guard let encoder = buffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
        throw .encoderInit(command)
      }

      // Add the needed data for GPU rendering
      if let viewProjBuffer = viewProjBuffer {
        encoder.setVertexBuffer(viewProjBuffer, offset: 0, index: 2)
      }

      encoder.setFragmentBytes(
        &fragmentUniform,
        length: MemoryLayout<StandardFragmentUniform>.size,
        index: FragmentBufferIndex.uniform.rawValue
      )
      encoder.setFragmentBytes(
        lightsData,
        length: MemoryLayout<Light>.stride * lightsData.count,
        index: FragmentBufferIndex.lights.rawValue
      )

      // Render!
      command.render(encoder: encoder, depthStencil: depthStencilState)
    }

    buffer.present(layerDrawable)
    buffer.commit()
  }

  //MARK: - Pass Helpers

  private func renderPassDescriptor(buffer: MTLCommandBuffer, layerDrawable: CAMetalDrawable, depthTexture: MTLTexture) -> MTLRenderPassDescriptor {
    // Render Command Pass
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = layerDrawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .load
    renderPassDescriptor.depthAttachment.texture = depthTexture
    renderPassDescriptor.depthAttachment.loadAction = .load
    renderPassDescriptor.depthAttachment.storeAction = .store

    return renderPassDescriptor
  }

  private func clearPass(buffer: MTLCommandBuffer, layerDrawable: CAMetalDrawable, depthTexture: MTLTexture) {
    let clearPassDescriptor = MTLRenderPassDescriptor()
    clearPassDescriptor.colorAttachments[0].texture = layerDrawable.texture
    clearPassDescriptor.colorAttachments[0].loadAction = .clear
    clearPassDescriptor.depthAttachment.texture = depthTexture
    clearPassDescriptor.depthAttachment.loadAction = .clear
    clearPassDescriptor.depthAttachment.storeAction = .store
    
    let clearColor = 0.0

    clearPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
      red: clearColor,
      green: clearColor,
      blue: clearColor,
      alpha: 1.0
    )

    let renderEncoder = buffer.makeRenderCommandEncoder(descriptor: clearPassDescriptor)!
    renderEncoder.endEncoding()
  }

  //MARK: - Data Helpers

  private func standardFragmentUniform(from commands: [CommandAndPrevious], lightCount: Int) -> StandardFragmentUniform {
    if let cameraCommand = commands.first(where: { $0.0 is PlaceCamera })?.0 as? PlaceCamera {
      return StandardFragmentUniform(camPos: simd_float4(cameraCommand.transform.value.translation, 1),
                                     lightCount: simd_float4(x: Float(lightCount), y: 0, z: 0, w: 0))
    }
    
    return StandardFragmentUniform(camPos: .zero, lightCount: simd_float4(x: Float(lightCount), y: 0, z: 0, w: 0))
  }

  private func viewProjectionBuffer(from commands: [CommandAndPrevious]) -> MTLBuffer? {
    if let cameraCommand = commands.first(where: { $0.0 is PlaceCamera })?.0 as? PlaceCamera {
      return cameraCommand.storage.viewProjBuffer
    }

    return defaultProjViewBuffer
  }
}
