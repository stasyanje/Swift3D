//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import simd

public struct GeometryNode: Node, AcceptsShader {
  public let id: String
  
  public var drawCommands: [any MetalDrawable] { [command] }
  
  private let command: RenderModel

  public init(id: String, shape: Primitive) {
    self.id = id
    
    let shaderPipeline: UnlitShader = switch shape {
    case .cone,
         .capsule,
         .cylinder,
         .octa,
         .sphere,
         .triangle:
      UnlitShader(.red)
    case .cube:
      UnlitShader(.white)
    }
    
    self.command = RenderModel(
      id: id,
      transform: .identity,
      shaderPipeline: shaderPipeline,
      model: .primitive(shape)
    )
  }
}
