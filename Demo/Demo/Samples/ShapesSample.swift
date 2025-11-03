//
//  ShapesSample.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import SwiftUI
import UIKit

import Swift3D
import simd

fileprivate class Data {
  var rotation: Float = 0
}

struct ShapesSample: View {
  private let data = Data()
  private let cameraController = TouchCameraController(minDistance: 8, maxDistance: 14)

  var body: some View {
    ZStack {
      Swift3DView {
        TouchCameraNode(controller: cameraController, skybox: .skybox(CubeMap(imageName: "stadiumEnv")))
      }
      .touchCamera(controller: cameraController)
      .frame(maxHeight: .infinity)
    }

    VStack {
      Text("🎁 Plenty of shapes to toy around with. ♦️")
      ZStack {
          Swift3DView(updateLoop: { frame in
            data.rotation += Float(frame.deltaTime)
            cameraController.update(delta: frame.deltaTime)
          }) {
            TouchCameraNode(controller: cameraController, skybox: .gradient())
            funLights
            node(for: .sphere)
            node(for: .cylinder)
            node(for: .cone)
            node(for: .capsule)
            node(for: .cube)
            node(for: .octa(divisions: 0))
          }
          .touchCamera(controller: cameraController)
          .frame(maxHeight: .infinity)
      }
    }
  }
  
  // MARK: - Private
  
  private func node(for primitive: Primitive) -> GeometryNode {
    let translation: simd_float3 = switch primitive {
    case .capsule: .up * 3 + 2 * .right
    case .cone: 3 * .down + 2 * .left
    case .cube: 2 * .right
    case .cylinder: 2 * .left
    case .octa: 3 * .down + 2 * .right
    case .sphere: (3 * .up) + (2 * .left)
    case .triangle: .zero
    }
    
    let scale: simd_float3 = switch primitive {
    case .cube: .one * 1.5
    case .octa: .one * 2.5
    case .capsule, .cone, .cylinder, .sphere, .triangle: .one
    }
    
    let rotation: float4x4 = .rotated(angle: data.rotation, axis: normalize(.up + .right))
    
    return GeometryNode(
      id: String(describing: primitive),
      renderable: .primitive(primitive),
      transform: rotation * .translated(translation) * .scaled(scale),
      shader: .uvColored
    )
  }

  private var funLights: some Node {
    GroupNode(id: "lights") {
      LightNode(id: "Ambient", direction: .ambient)
        .colored(color: .white.opacity(0.15))
      LightNode(id: "Directional", direction: .directional)
        .colored(color: .orange.opacity(0.4))
        .transform(.lookAt(eye: .zero, look: simd_float3(x: 0.5, y: 0.5, z: 0.5), up: .up))
      LightNode(id: "Directional2", direction: .directional)
        .colored(color: .blue.opacity(0.5))
        .transform(.lookAt(eye: .zero, look: simd_float3(x: -0.5, y: -0.5, z: 0.5), up: .up))
    }
  }
}

private struct Preview: PreviewProvider {
  static var previews: some View {
    ShapesSample()
  }
}

