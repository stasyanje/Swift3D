import Foundation
import UIKit
import SwiftUI
import Metal
import MetalKit

public class MetalView: UIView {
  @available(*, unavailable) public required init?(coder: NSCoder) { nil }
  public override class var layerClass: AnyClass { CAMetalLayer.self }
  private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
  
  // MARK: - Type definitions
  
  private enum Error: Swift.Error {
    case deviceInit
  }
  
  public struct Frame {
    public let deltaTime: Double
  }
  
  public typealias Update = (_ frame: Frame) -> Void
  public typealias ContentFactory = () -> any Node
    
  private let renderer: MetalRenderer
  private let bufferFactory: MetalBufferFactory
  private let scene: MetalScene3D
  
  private let timelineLoop = TimelineLoop(fps: 60)
  private let updateLoop: (_ frame: Frame) -> Void
  
  private var lastUpdateTime = CACurrentMediaTime()
  private var preferredTimeBetweenUpdates = 0.0
    
  // MARK: Setup / Teardown
  
  public init(
    preferredFps: Int,
    updateLoop: @escaping Update,
    contentFactory: @escaping ContentFactory
  ) throws {
    guard let device = MTLCreateSystemDefaultDevice() else {
      throw Error.deviceInit
    }
    bufferFactory = MetalBufferFactory(device: device)
    renderer = try MetalRenderer(device: device, bufferFactory: bufferFactory)
    scene = MetalScene3D(
      device: device,
      shaderLibrary: try MetalShaderLibrary(device: device, bufferFactory: bufferFactory),
      contentFactory: contentFactory
    )
    
    self.updateLoop = updateLoop
    self.preferredTimeBetweenUpdates = 1.0 / Double(preferredFps)
    super.init(frame: .zero)
    
    let metalLayer = metalLayer
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.contentsScale = UIScreen.main.scale

    timelineLoop.start { [weak self] frameTime in
      do {
        try self?.render(time: frameTime)
      } catch {
        fatalError(String(describing: error))
      }
    }
    
    Profiler.InstanceCount.increment(MetalView.self)
  }
  
  deinit {
    timelineLoop.stop()
    Profiler.InstanceCount.decrement(MetalView.self)
  }
  
  // MARK: - Private
  
  private func render(time: CFTimeInterval) throws {
    guard let drawable = metalLayer.nextDrawable() else {
      return
    }

    let delta = time - lastUpdateTime
    let newFrame = delta >= preferredTimeBetweenUpdates
    
    if newFrame {
      lastUpdateTime = time
      updateLoop(.init(deltaTime: delta))
    }
    
    let commands = scene.prepareCommands(
      surfaceAspect: Float(bounds.width / bounds.height),
      time: time,
      invalidate: newFrame
    )

    try renderer.render(time: time, layerDrawable: drawable, commands: commands)
  }
}

// MARK: Update Loop

private class TimelineLoop {
  let fps: Float

  private var tick: ((CFTimeInterval) -> Void)?
  private var dp: CADisplayLink?

  init(fps: Float) {
    self.fps = fps
  }
  
  deinit {
    dp?.invalidate()
  }

  func start(callback: @escaping (CFTimeInterval) -> Void) {
    tick = callback

    dp = CADisplayLink(target: self, selector: #selector(update))
    dp?.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: fps, preferred: fps)
    dp?.add(to: .current, forMode: .common)
  }

  func stop() {
    dp?.invalidate()
  }

  @objc private func update() {
    if let tick = tick {
      autoreleasepool {
        tick(CACurrentMediaTime())
      }
    }
  }
}
