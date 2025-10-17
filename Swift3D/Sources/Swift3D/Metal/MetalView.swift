import Foundation
import UIKit
import SwiftUI
import Metal
import MetalKit

public class MetalView: UIView {
  private enum Error: Swift.Error {
    case deviceInit
  }
  
  public override class var layerClass: AnyClass { CAMetalLayer.self }
  private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
    
  private let renderer: MetalRenderer
  private let bufferFactory: MetalBufferFactory
  private let scene: MetalScene3D
  
  private let timelineLoop = TimelineLoop(fps: 60)
  private let updateLoop: (_ deltaTime: Double) -> Void
  private let content: () -> any Node
  
  private var lastUpdateTime = CACurrentMediaTime()
  private var preferredTimeBetweenUpdates = 0.0
    
  // MARK: Setup / Teardown
  
  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    assertionFailure("init(coder:) has not been implemented")
    return nil
  }
  
  public init(
    preferredFps: Int,
    updateLoop: @escaping (_ deltaTime: Double) -> Void,
    contentFactory: @escaping () -> any Node
  ) throws {
    guard let device = MTLCreateSystemDefaultDevice() else {
      throw Error.deviceInit
    }
    bufferFactory = MetalBufferFactory(device: device)
    renderer = try MetalRenderer(device: device, bufferFactory: bufferFactory)
    let shaderLibrary = try MetalShaderLibrary(device: device, bufferFactory: bufferFactory)
    scene = MetalScene3D(device: device, shaderLibrary: shaderLibrary)
    
    self.content = contentFactory
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
  }
  
  deinit {
    timelineLoop.stop()
  }
  
  // MARK: - Private
  
  private func render(time: CFTimeInterval) throws {
    guard let drawable = metalLayer.nextDrawable() else {
      return
    }

    let delta = time - lastUpdateTime
    if delta >= preferredTimeBetweenUpdates {
      lastUpdateTime = time
      updateLoop(delta)
      scene.setContent(content(), surfaceAspect: Float(bounds.width / bounds.height))
    }

    // Update command values for GPU & Time (primarily used for transitions)
    scene.commands.forEach { (command, previousStorage) in
      command.storage.update(time: time, command: command, previous: previousStorage)
    }
    
    try renderer.render(time: time, layerDrawable: drawable, commands: scene.commands)
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
