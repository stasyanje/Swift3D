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
        TouchCameraNode(controller: cameraController)
        lights

        ModelNode(id: "BlueTile", url: .model("BlueTile.usdz"))
          .shaded(.pbr)
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
      LightNode(id: "ambient", direction: .ambient)
        .colored(color: .white, intensity: 0.1)

      GroupNode(id: "White Light") {
        LightNode(id: "light", direction: .point)
          .colored(color: .white, intensity: 8)

        GeometryNode(id: "sphere", shape: .sphere)
          .shaded(.unlit(.white))
          .scaled(.one * 0.1)
      }
      .translated(.up * 1.5)
      .rotated(angle: rotation, axis: .right)

      GroupNode(id: "Green Light") {
        LightNode(id: "light", direction: .point)
          .colored(color: .green, intensity: 8)

        GeometryNode(id: "sphere", shape: .sphere)
          .shaded(.unlit(.green))
          .scaled(.one * 0.1)
      }
      .translated(.back * 1.5)
      .rotated(angle: rotation, axis: .up + .left)

      GroupNode(id: "Red Light") {
        LightNode(id: "light", direction: .point)
          .colored(color: .purple, intensity: 8)

        GeometryNode(id: "sphere", shape: .sphere)
          .shaded(.unlit(.purple))
          .scaled(.one * 0.1)
      }
      .translated(.forward * 1.5)
      .rotated(angle: -rotation, axis: .up + .right)
    }
  }
}
