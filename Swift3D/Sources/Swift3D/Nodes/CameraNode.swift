//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 1/21/23.
//

import Foundation
import SwiftUI
import simd

public struct OrthographicSettings {
  let left: Float
  let right: Float
  let top: Float
  let bottom: Float

  let nearZ: Float
  let farZ: Float
  
  public init(viewSpace: CGRect, zNear: Float = 0.1, zFar: Float = 100) {
    self.left = Float(viewSpace.minX)
    self.right = Float(viewSpace.maxX)
    self.top = Float(viewSpace.maxY)
    self.bottom = Float(viewSpace.minY)
    self.nearZ = zNear
    self.farZ = zFar
  }
}

public struct PerspectiveSettings {
  let fov: Float
  let zNear: Float
  let zFar: Float
  
  public init(fov: Float = 1.0472, zNear: Float = 0.1, zFar: Float = 100) {
    self.fov = fov
    self.zNear = zNear
    self.zFar = zFar
  }
}

public enum CameraProjection {
  case orthographic(OrthographicSettings)
  case perspective(PerspectiveSettings)

  func matrix(aspect: Float) -> float4x4 {
    switch self {
    case .orthographic(let settings):
      return float4x4.makeOrthographic(left: settings.left,
                                       right:settings.right,
                                       bottom: settings.bottom,
                                       top: settings.top,
                                       nearZ: settings.nearZ,
                                       farZ: settings.farZ)
    case .perspective(let settings):
      return float4x4.makePerspective(fovYRadians: settings.fov,
                                      aspect: aspect,
                                      nearZ: settings.zNear,
                                      farZ: settings.zFar)
    }
  }
}

public struct CameraNode: Node {
  public let id: String
  
  public var drawCommands: [any MetalDrawable] { [command] }
  
  private let command: PlaceCamera
  
  public init(
    id: String,
    transform: MetalTransform = .identity,
    projection: CameraProjection = .perspective(.init()),
    animations: [NodeTransition]? = nil,
    skyboxShader: MetalDrawable_Shader? = nil
  ) {
    self.id = id
    self.command = PlaceCamera(
      id: id,
      transform: transform,
      animations: animations,
      shaderPipeline: skyboxShader,
      projection: projection
    )
  }
}
