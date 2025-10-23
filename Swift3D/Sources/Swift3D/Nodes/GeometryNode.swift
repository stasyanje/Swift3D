//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import simd

public struct GeometryNode: Node, AcceptsShader {
  public enum Shape {
    case capsule
    case cone
    case cube
    case cylinder
    case octa(divisions: Int)
    case sphere
    case triangle
  }
  
  public let id: String
  public let shape: Shape
  
  public var drawCommands: [any MetalDrawable] { [command] }
  
  private let command: RenderGeometry

  public init(id: String, shape: Shape) {
    self.id = id
    self.shape = shape
    
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
    
    let geometry: MetalDrawable_Geometry = switch shape {
    case .capsule: Capsule()
    case .cone: Cone()
    case .cube: Cube()
    case .cylinder: Cylinder()
    case .octa(let divisions): Octahedron(divisions: divisions)
    case .sphere: Sphere()
    case .triangle: Triangle()
    }
    
    self.command = RenderGeometry(
      id: id,
      transform: .identity,
      geometry: geometry,
      shaderPipeline: shaderPipeline,
      renderType: .triangles,
      animations: nil,
      cullBackfaces: false
    )
  }
}
