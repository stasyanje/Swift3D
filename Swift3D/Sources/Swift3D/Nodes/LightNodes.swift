//
//  AmbientLightNode.swift
//  
//
//  Created by Andrew Zimmer on 1/31/23.
//

import Foundation
import simd

public struct LightNode: Node, AcceptsColored {
  public let id: String
  public var drawCommands: [any MetalDrawable] { [drawable] }
  
  private let drawable: PlaceLight
  
  public init(id: String, direction: LightDirection) {
    self.id = id
    self.drawable = PlaceLight(
      id: id,
      transform: .identity,
      direction: direction,
      color: direction == .point ? simd_float4(1, 1, 1, 10) : .one,
      animations: nil
    )
  }
}
