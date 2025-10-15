//
//  IntroAnimationSample.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/15/23.
//

import Foundation
import SwiftUI
import Swift3D
import simd

struct IntroAnimationSample: View {
  private enum Constants {
    static let onScreen = simd_float3(x: .pi * 4, y: 0, z: -2.5)
    static let offScreen = simd_float3(x: 0, y: -20, z: -40)
  }
  
  @State private var fastSpring = Spring(target: Constants.offScreen, strength: 0.3, damper: 3)
  @State private var slowSpring = Spring(target: Constants.offScreen, strength: 0.175, damper: 2.5)

  @State private var rotation: Float = 0
  @State private var show = false

  var body: some View {
    VStack {
      ZStack {
        Swift3DView(updateLoop: { delta in
          let target = show ? Constants.onScreen : Constants.offScreen
          slowSpring.target = target
          fastSpring.target = target
          
          slowSpring.update(deltaTime: delta)
          fastSpring.update(deltaTime: delta)

          rotation += Float(delta) * .pi
        }) {
          CameraNode(id: "MainCamera")
            .skybox(.skybox(low: .white, mid: .white, high: .white))
            .translated(.back * 20)
          FunLights(id: "lights")

          ModelNode(id: "title", url: .model("title.obj"))
            .shaded(.standard(albedo: Color(hex: 0x89CFF0)))
            .overrideDefaultTextures()
            .rotated(angle: slowSpring.value.x, axis: .up)
            .translated(.up * fastSpring.value.y)

          OctaNode(id: "octa", divisions: 0)
            .shaded(.uvColored)
            .scaled(.one * 1.5)
            .rotated(angle: rotation, axis: .up)
            .translated(.up * slowSpring.value.z)
        }
        VStack(spacing: 16) {
          Text("Tap")
            .font(.largeTitle)
          Text("👆")
            .font(.largeTitle)
          Divider()
          Text("for 🚀🚀🚀")
        }
        .offset(CGSize(width: 0, height: show ? -UIScreen.main.bounds.height : 0))
      }

    }
    .ignoresSafeArea()
    .frame(maxHeight: .infinity)
    .padding()
    .onTapGesture {
      withAnimation {
        self.show.toggle()
      }
    }
  }
}

private struct Preview: PreviewProvider {
  static var previews: some View {
    IntroAnimationSample()
  }
}
