//
//  PBRSample.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/27/23.
//

import Foundation
import SwiftUI
import Swift3D
import simd

struct PBRSample: View {
  @State private var rotation: Float = 0
  
  let cameraController = TouchCameraController(minDistance: 2, maxDistance: 5)

  var body: some View {
    ZStack {
      Swift3DView(updateLoop: { frame in
        cameraController.update(delta: frame.deltaTime)
        rotation += Float(frame.deltaTime) * .pi / 5
      }) {
        TouchCameraNode(controller: cameraController, skybox: .gradient())
        lights
        GeometryNode(
          id: "BlueTile",
          renderable: .url(.resource(at: "BlueTile.usdz")),
          shader: .pbr
        )
      }
      .touchCamera(controller: cameraController)

      VStack {
        Text("⚡️ Dynamic Lighting + Physically Based Materials ⚡️")
          .font(.title2)
        Spacer()
        Text("This sample was a lot of fun to make! 💜")
          .font(.caption)
        Text("🔢 Check out _Shaders/Lighting.metal_ for maths!")
          .font(.caption)
      }.multilineTextAlignment(.center)
       .padding()
    }
  }

  private var lights: some Node {
    GroupNode(id: "Lights") {
      LightNode(
        id: "ambient",
        direction: .ambient,
        color: simd_float4(.one, 0.1)
      )

      GroupNode(id: "White Light") {
        LightNode(
          id: "light",
          direction: .point,
          color: simd_float4(.one, 8)
        )

        GeometryNode(
          id: "sphere",
          renderable: .primitive(.sphere),
          transform: .scaled(.one * 0.1),
          shader: .unlit(.white)
        )
      }
      .translated(.up * 1.5)
      .rotated(angle: rotation, axis: .right)

      GroupNode(id: "Green Light") {
        LightNode(
          id: "light",
          direction: .point,
          color: simd_float4(0.2, 0.8, 0.2, 8)
        )

        GeometryNode(
          id: "sphere",
          renderable: .primitive(.sphere),
          transform: .scaled(.one * 0.1),
          shader: .unlit(.green)
        )
      }
      .translated(.back * 1.5)
      .rotated(angle: rotation, axis: .up + .left)

      GroupNode(id: "Red Light") {
        LightNode(
          id: "light",
          direction: .point,
          color: simd_float4(0.2, 0.2, 0.8, 8)
        )

        GeometryNode(
          id: "sphere",
          renderable: .primitive(.sphere),
          transform: .scaled(.one * 0.1),
          shader: .unlit(.purple)
        ) 
      }
      .translated(.forward * 1.5)
      .rotated(angle: -rotation, axis: .up + .right)
    }
  }
}
