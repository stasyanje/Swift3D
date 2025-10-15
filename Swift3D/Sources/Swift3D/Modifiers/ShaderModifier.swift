//
//  ShaderPipelineModifier.swift
//  
//
//  Created by Andrew Zimmer on 1/31/23.
//

import Foundation
import simd
import SwiftUI

public struct ShaderModifier: NodeModifier {
  let shader: any MetalDrawable_Shader
  
  public func printedTree(content: any Node) -> [String] {
    content.printedTree
  }
  
  public func drawCommands(content: any Node) -> [any MetalDrawable] {    
    return content.drawCommands.map {
      if var cmd = $0 as? (any HasShaderPipeline & MetalDrawable) {
        cmd.shaderPipeline = shader
        return cmd
      }
      return $0
    }
  }
}

public struct OverrideTexturesModifier: NodeModifier {
  let override: Bool

  public func printedTree(content: any Node) -> [String] {
    content.printedTree
  }

  public func drawCommands(content: any Node) -> [any MetalDrawable] {
    return content.drawCommands.map {
      if var cmd = $0 as? RenderModel {
        cmd.overrideTextures = override
        return cmd
      }
      return $0
    }
  }
}

// MARK: - Node Extension

public protocol AcceptsShader: Node {
  func shaded(_ shader: any MetalDrawable_Shader) -> ModifiedNodeContent<Self, ShaderModifier>
}

extension AcceptsShader {
  public func shaded(_ shader: any MetalDrawable_Shader) -> ModifiedNodeContent<Self, ShaderModifier> {
    return self.modifier(ShaderModifier(shader: shader))
  }
}

public protocol AcceptsShaderWithDefaultTextures: Node {
  func shaded(_ shader: any MetalDrawable_Shader) -> ModifiedNodeContent<Self, ShaderModifier>
  func overrideDefaultTextures() -> ModifiedNodeContent<Self, OverrideTexturesModifier>
}

extension AcceptsShaderWithDefaultTextures {
  public func shaded(_ shader: any MetalDrawable_Shader) -> ModifiedNodeContent<Self, ShaderModifier> {
    return self.modifier(ShaderModifier(shader: shader))
  }
  
  public func overrideDefaultTextures() -> ModifiedNodeContent<Self, OverrideTexturesModifier> {
    self.modifier(OverrideTexturesModifier(override: true))
  }
}

extension ModifiedNodeContent: AcceptsShader where Content: AcceptsShader, Modifier: NodeModifier { }
extension ModifiedNodeContent: AcceptsShaderWithDefaultTextures where Content: AcceptsShaderWithDefaultTextures, Modifier: NodeModifier { }
