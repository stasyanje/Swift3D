//
//  MetalScene3D.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import Foundation
import Metal

final class MetalScene3D {
  private let device: MTLDevice
  private let shaderLibrary: MetalShaderLibrary
  private let contentFactory: () -> any Node
  
  private var commands: [MetalDrawable] = []
    
  init(device: MTLDevice, shaderLibrary: MetalShaderLibrary, contentFactory: @escaping () -> any Node) {
    self.device = device
    self.shaderLibrary = shaderLibrary
    self.contentFactory = contentFactory
  }
  
  func prepareCommands(surfaceAspect: Float, time: Double, invalidate: Bool) -> [MetalDrawable] {
    if invalidate {
      commands = buildCommands(surfaceAspect: surfaceAspect)
    }
    
    // Update command values for GPU & Time (primarily used for transitions)
    for command in commands {
      command.update(time: time)
    }
    
    return commands
  }
  
  private func buildCommands(surfaceAspect: Float) -> [MetalDrawable] {
    contentFactory().drawCommands.map { command in
      let measure = Profiler.Clock.measureAverage("\(type(of: command)).build"); defer { measure() }
      
      command.build(
        previous: commands.first { $0.id == command.id },
        device: device,
        shaderLibrary: shaderLibrary,
        surfaceAspect: surfaceAspect
      )
      
      return command
    }
  }
}
