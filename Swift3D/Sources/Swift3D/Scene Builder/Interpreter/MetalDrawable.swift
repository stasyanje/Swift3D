//
//  DrawCommand.swift
//  
//
//  Created by Andrew Zimmer on 1/21/23.
//

import Foundation
import UIKit
import Metal
import simd

// Used for data namespacing.
public enum MetalDrawableData {}

extension MetalDrawableData {
  public struct Transform {
    public let value: float4x4

    static func transform(_ value: float4x4) -> Transform {
      .init(value: value)
    }
    
    static var identity: Transform {
      .init(value: .identity)
    }
  }
}

// MARK: - Metal Drawable

public protocol MetalDrawable {
  var id: String { get set }
  var transform: MetalDrawableData.Transform { get set }
  var animations: [NodeTransition]? { get set }
  
  var needsRender: Bool { get }
  
  func update(time: CFTimeInterval)
  func render(encoder: MTLRenderCommandEncoder, depthStencil: MTLDepthStencilState?)
  
  func build(
    previous: MetalDrawable?,
    device: MTLDevice,
    shaderLibrary: MetalShaderLibrary,
    geometryLibrary: MetalGeometryLibrary,
    surfaceAspect: Float
  )
}

// MARK: - Animated Attributes
extension MetalDrawable {
  func attribute<T: Lerpable>(at time: CFTimeInterval,
                         cur: T, 
                         prev: T?, 
                         attributes: [NodeTransition.Attribute] = [.all]) -> T? {    
    guard let animation = animations?.first(where: { attributes.contains($0.attribute) }),
          let prev = prev else {            
      return nil
    }
    
    let percent = animation.interpolate(time: time)
    return T.lerp(prev, cur, percent)
  }
}

extension Array where Element == NodeTransition {
  func with(_ attributes: [NodeTransition.Attribute]) -> NodeTransition? {
    self.first(where: { attributes.contains($0.attribute) })
  }
}

extension Lerpable {
  func attribute(at time: Double, prev: Self?, animation: NodeTransition?) -> Self {
    guard let animation = animation,
          let prev = prev else {
      return self
    }

    let percent = animation.interpolate(time: time)
    return Self.lerp(prev, self, percent)
  }
}
