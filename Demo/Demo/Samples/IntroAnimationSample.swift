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
  
  private struct State {
    var fastSpring = Spring(target: Constants.offScreen, strength: 0.3, damper: 3)
    var slowSpring = Spring(target: Constants.offScreen, strength: 0.175, damper: 2.5)

    var rotation: Float = 0
    var show = false
  }
  
  @SwiftUI.State private var state = State()

  var body: some View {
    VStack {
      ZStack {
        swift3DView
        VStack(spacing: 16) {
          Text("Tap")
            .font(.largeTitle)
          Text("👆")
            .font(.largeTitle)
          Divider()
          Text("for 🚀🚀🚀")
        }
        .offset(CGSize(width: 0, height: state.show ? -UIScreen.main.bounds.height : 0))
      }

    }
    .ignoresSafeArea()
    .frame(maxHeight: .infinity)
    .padding()
    .onTapGesture {
      withAnimation {
        self.state.show.toggle()
      }
    }
  }
  
  // MARK: - Private
  
  private var swift3DView: some View {
    Swift3DView(
      updateLoop: reduce(frame:),
      contentFactory: {
        let state = state
        
        CameraNode(
          id: "MainCamera",
          transform: .translated(.back * 20),
          skyboxShader: .gradient()
        )
          
        FunLights(id: "lights")
        
        GeometryNode(
          id: "title",
          renderable: .url(.resource(at: "title.obj"), overrideTextures: true),
          transform: .rotated(angle: state.slowSpring.value.x, axis: .up) *
            .translated(.up * state.fastSpring.value.y),
          shader: .standard(albedo: Color(hex: 0x89CFF0))
        )
        
        GeometryNode(
          id: "cube",
          renderable: .primitive(.octa(divisions: 0)),
          transform: .scaled(.one * 1.5) *
            .rotated(angle: state.rotation, axis: .up) *
            .translated(.up * state.slowSpring.value.z),
          shader: .uvColored
        )
      }
    )
  }
  
  private func reduce(frame: MetalView.Frame) {
    let target = state.show ? Constants.onScreen : Constants.offScreen
    let delta = frame.deltaTime
    
    state.slowSpring.target = target
    state.fastSpring.target = target
    
    state.slowSpring.update(deltaTime: delta)
    state.fastSpring.update(deltaTime: delta)
    
    state.rotation += Float(delta) * .pi
  }
}

private struct Preview: PreviewProvider {
  static var previews: some View {
    IntroAnimationSample()
  }
}
