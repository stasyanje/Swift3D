//
//  StandardLighting.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/10/23.
//

import Foundation
import Swift3D
import simd
import SwiftUI

struct StandardLighting: Node {
  let id: String

  var body: some Node {
    LightNode(
      id: "Ambient",
      direction: .ambient,
      color: simd_float4(.one, 0.5)
    )

    LightNode(
      id: "Directional",
      direction: .directional,
      transform: .lookAt(eye: .zero, look: simd_float3(x: 0, y: 0, z: -0.5), up: .up),
      color: simd_float4(.one, 0.25)
    )
  }
}

struct FunLights: Node {
  let id: String
  var body: some Node {
    LightNode(
      id: "Ambient",
      direction: .ambient,
      color: simd_float4(.one, 0.25)
    )
    LightNode(
      id: "Directional",
      direction: .directional,
      transform: .lookAt(eye: .zero, look: simd_float3(x: 0.5, y: 0.5, z: 0.5), up: .up),
      color: simd_float4(0.5, 0.5, 0.2, 0.4)
    )
    LightNode(
      id: "Directional2",
      direction: .directional,
      transform: .lookAt(eye: .zero, look: simd_float3(x: -0.5, y: -0.5, z: 0.5), up: .up),
      color: simd_float4(0.2, 0.2, 0.8, 0.5)
    )
  }
}
