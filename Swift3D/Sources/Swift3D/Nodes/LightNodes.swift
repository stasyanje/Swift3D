//
//  AmbientLightNode.swift
//  
//
//  Created by Andrew Zimmer on 1/31/23.
//

import Foundation
import simd

public struct LightNode: Node {
  public let id: String
  public var drawCommands: [any MetalDrawable] { [drawable] }
  
  private let drawable: PlaceLight
  
  public init(
    id: String,
    direction: LightDirection,
    transform: MetalTransform = .identity,
    color: simd_float4 = .one,
  ) {
    self.id = id
    self.drawable = PlaceLight(
      id: id,
      transform: transform,
      direction: direction,
      color: color,
      animations: nil
    )
  }
}
