//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 1/22/23.
//

import Foundation
import simd

public struct TransformModifier: NodeModifier {
  let transform: MetalTransform
  
  public func printedTree(content: any Node) -> [String] {
    content.printedTree
  }
  
  public func drawCommands(content: any Node) -> [any MetalDrawable] {    
    content.drawCommands.map { command in
      var command = command
      command.transform = transform * command.transform
      return command
    }
  }
}

// MARK: - Node Extension

extension Node {
 public func transform(_ transform: MetalTransform) -> ModifiedNodeContent<Self, TransformModifier> {
   self.modifier(TransformModifier(transform: transform))
  }

  public func translated(_ translation: simd_float3) -> ModifiedNodeContent<Self, TransformModifier> {
    self.transform(.translated(translation))
  }

  public func rotated(angle: Float, axis: simd_float3) -> ModifiedNodeContent<Self, TransformModifier> {
    self.transform(.rotated(angle: angle, axis: normalize(axis)))
  }

  public func scaled(_ scale: simd_float3) -> ModifiedNodeContent<Self, TransformModifier> {
    self.transform(.scaled(scale))
  }
}
