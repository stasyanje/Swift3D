//
//  MetalScene3D.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import Foundation
import UIKit
import Metal

final class MetalScene3D {
  private let device: MTLDevice
  private let shaderLibrary: MetalShaderLibrary
  private let geometryLibrary: MetalGeometryLibrary
  private let contentFactory: () -> any Node
  
  private var commands: [any MetalDrawable] = []
    
  init(device: MTLDevice, shaderLibrary: MetalShaderLibrary, contentFactory: @escaping () -> any Node) {
    self.device = device
    self.shaderLibrary = shaderLibrary
    self.geometryLibrary = MetalGeometryLibrary(device: device)
    self.contentFactory = contentFactory
  }
  
  func buildCommands(surfaceAspect: Float, time: Double, invalidate: Bool) -> [any MetalDrawable] {
    if invalidate {
      commands = buildCommands(surfaceAspect: surfaceAspect)
    }
    
    // Update command values for GPU & Time (primarily used for transitions)
    commands.forEach { command in
      command.update(time: time)
    }
    
    return commands
  }
  
  private func buildCommands(surfaceAspect: Float) -> [any MetalDrawable] {
    contentFactory().drawCommands.map { [commands] command in
      command.storage.build(
        command,
        previous: commands.first { $0.id == command.id }?.storage,
        device: device,
        shaderLibrary: shaderLibrary,
        geometryLibrary: geometryLibrary,
        surfaceAspect: surfaceAspect
      )
      
      return command
    }
  }
}
