//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import SwiftUI
import simd

public struct GeometryNode: Node {
  public let id: String
  public let transform: MetalTransform
  public let drawCommands: [MetalDrawable]
    
  public init(
    id: String,
    renderable: Renderable,
    transform: MetalTransform = .identity,
    shader: MetalDrawable_Shader? = nil
  ) {
    self.id = id
    self.transform = transform
    
    let shaderPipeline: MetalDrawable_Shader = switch renderable {
    case .primitive(.cube): .unlit(.red)
    case .primitive: .unlit(.white)
    case .url: .standard(albedo: Color.white)
    }
    
    self.drawCommands = [
      RenderModel(
        id: id,
        transform: transform,
        shaderPipeline: shader ?? shaderPipeline,
        animations: nil,
        model: renderable
      )
    ]
  }
}
