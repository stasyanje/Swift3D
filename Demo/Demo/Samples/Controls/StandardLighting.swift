//
//  StandardLighting.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/10/23.
//

import Foundation
import Swift3D
import simd

struct StandardLighting: Node {
  let id: String

  var body: some Node {
    LightNode(id: "Ambient", direction: .ambient)
      .colored(color: .white, intensity: 0.5)

    LightNode(id: "Directional", direction: .directional)
      .colored(color: .white, intensity: 0.25)
      .transform(.lookAt(eye: .zero, look: simd_float3(x: 0, y: 0, z: -0.5), up: .up))
  }
}

struct FunLights: Node {
  let id: String
  var body: some Node {
    LightNode(id: "Ambient", direction: .ambient)
      .colored(color: .white, intensity: 0.25)
    LightNode(id: "Directional", direction: .directional)
      .colored(color: .yellow, intensity: 0.4)
      .transform(.lookAt(eye: .zero, look: simd_float3(x: 0.5, y: 0.5, z: 0.5), up: .up))
    LightNode(id: "Directional2", direction: .directional)
      .colored(color: .teal, intensity: 0.5)
      .transform(.lookAt(eye: .zero, look: simd_float3(x: -0.5, y: -0.5, z: 0.5), up: .up))
  }
}
