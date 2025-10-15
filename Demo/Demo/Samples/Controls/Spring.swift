//
//  TransformVelocity.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/16/23.
//

import Foundation
import simd

// Handles updating transform values with acceleration & velocity
struct Spring {
  let strength: Float
  let damper: Float

  var target: simd_float3
  private var velocity: simd_float3 = .zero
  
  private(set) var value: simd_float3

  init(target: simd_float3, strength: Float, damper: Float) {
    self.target = target
    self.value = target
    self.strength = strength
    self.damper = damper
  }

  mutating func update(deltaTime: CFTimeInterval) {
    let distanceToTarget = abs(target - value)
    let directionToTarget = normalize(target - value)
    let deltaTimeF = Float(deltaTime)

    // Close enough
    guard length(distanceToTarget) > 0.01 else {
      velocity = .zero
      value = target
      return
    }

    let force = distanceToTarget * strength
    let acceleration = force * directionToTarget - velocity * damper
    velocity += acceleration * deltaTimeF
    value += velocity
  }
}
