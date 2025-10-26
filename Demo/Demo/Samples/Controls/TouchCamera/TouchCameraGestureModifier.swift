//
//  TouchCameraGestureModifier.swift
//  Demo
//
//  Created by Stanislav Kaliuzhnyi on 10/25/25.
//


import Foundation
import SwiftUI
import Swift3D
import simd

struct TouchCameraGestureModifier: ViewModifier {
  let controller: TouchCameraController
  func body(content: Content) -> some View {
    content.highPriorityGesture(DragGesture(minimumDistance: 0)
      .onChanged { gesture in
        controller.touchMoved(
          startLocation: gesture.startLocation,
          curLocation: gesture.location
        )
      }
      .onEnded({ gesture in
        if (abs(gesture.predictedEndTranslation.width) + abs(gesture.predictedEndTranslation.height)) < 0.25 {
          controller.touchTapped()
        }

        controller.touchEnded(predictedEndLocation: gesture.predictedEndLocation)
      })
    )
  }
}

// MARK: View Extensions for touch controls

extension View {
  func touchCamera(controller: TouchCameraController) -> some View {
    return self.modifier(TouchCameraGestureModifier(controller: controller))
  }
}
