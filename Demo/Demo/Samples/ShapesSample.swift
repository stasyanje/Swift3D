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
        TouchCamera(controller: cameraController, skybox: .skybox(.cube("stadiumEnv")))
      }
      .withCameraControls(controller: cameraController)
      .frame(maxHeight: .infinity)
    }

    VStack {
      Text("🎁 Plenty of shapes to toy around with. ♦️")
      ZStack {
          Swift3DView(updateLoop: { delta in
            data.rotation += Float(delta)
            cameraController.update(delta: delta)
          }) {
            TouchCamera(controller: cameraController,
                        skybox: .skybox())
            funLights

            GeometryNode(id: "sphere", shape: .sphere)
              .shaded(.uvColored)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(3 * .up + 2 * .left)

            GeometryNode(id: "cylinder", shape: .cylinder)
              .shaded(.uvColored)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(2 * .left)

            GeometryNode(id: "cone", shape: .cone)
              .shaded(.uvColored)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(3 * .down + 2 * .left)

            GeometryNode(id: "capsule", shape: .capsule)
              .shaded(.uvColored)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(3 * .up + 2 * .right)

            GeometryNode(id: "cube", shape: .cube)
              .shaded(.uvColored)
              .scaled(.one * 1.5)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(2 * (.right))

            GeometryNode(id: "octahed", shape: .octa(divisions: 0))
              .shaded(.uvColored)
              .scaled(.one * 2.5)
              .rotated(angle: data.rotation, axis: normalize(.up + .right))
              .translated(3 * .down + 2 * .right)
          }
          .withCameraControls(controller: cameraController)
          .frame(maxHeight: .infinity)
      }
    }
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

