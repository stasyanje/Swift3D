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
  
  private var commands: [any MetalDrawable] = []
    
  init(device: MTLDevice, shaderLibrary: MetalShaderLibrary) {
    self.device = device
    self.shaderLibrary = shaderLibrary
    self.geometryLibrary = MetalGeometryLibrary(device: device)
  }
  
  func buildCommands(_ drawCommands: [any MetalDrawable], surfaceAspect: Float) {
    commands = drawCommands.map { [commands] command in
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
  
  func updateCommands(time: Double) -> [any MetalDrawable] {
    // Update command values for GPU & Time (primarily used for transitions)
    commands.forEach { command in
      command.update(time: time)
    }
    
    return commands
  }
}
