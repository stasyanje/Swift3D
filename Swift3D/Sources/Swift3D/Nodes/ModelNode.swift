//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/9/23.
//

import Foundation
import SwiftUI
import simd

public struct ModelNode: Node, AcceptsShaderWithDefaultTextures {
  public let id: String
  public let url: URL
  public let drawCommands: [MetalDrawable]
    
  public init(id: String, url: URL, overrideTextures: Bool = false) {
    self.id = id
    self.url = url
    self.drawCommands = [
      RenderModel(
        id: id,
        transform: .identity,
        shaderPipeline: .standard(albedo: Color.white),
        animations: nil,
        model: .url(url, overrideTextures: overrideTextures)
      )
    ]
  }
}
