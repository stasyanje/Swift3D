import Foundation
import UIKit
import SwiftUI
import Metal
import MetalKit

public class MetalView: UIView {
  public override class var layerClass: AnyClass { CAMetalLayer.self }
  private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
  
  private let device: MTLDevice
  
  private let renderer: MetalRenderer
  private let shaderLibrary: MetalShaderLibrary
  private let geometryLibrary: MetalGeometryLibrary

  private let scene: MetalScene3D
  
  private let timelineLoop = TimelineLoop(fps: 60)
  private let updateLoop: (_ deltaTime: Double) -> Void
  private let content: () -> any Node
  
  private var lastUpdateTime = CACurrentMediaTime()
  private var preferredTimeBetweenUpdates = 0.0
  
  private var metalDepthTexture: MTLTexture?
  
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
      throw NSError(domain: "MTLCreateSystemDefaultDevice", code: -1)
    }
    self.device = device
    shaderLibrary = try MetalShaderLibrary(device: device)
    geometryLibrary = MetalGeometryLibrary(device: device)
    scene = MetalScene3D(device: device)
    renderer = MetalRenderer(device: device)
    
    self.content = contentFactory
    self.updateLoop = updateLoop
    self.preferredTimeBetweenUpdates = 1.0 / Double(preferredFps)
    
    // Needs initial frame to not be zero to create MTLDevice
    super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    
    let metalLayer = metalLayer
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.contentsScale = UIScreen.main.scale

    timelineLoop.start { [weak self] frameTime in
      self?.render(time: frameTime)
    }
  }
  
  deinit {
    timelineLoop.stop()
  }
  
  // MARK: - View Methods
  
  private var lastSize = CGSize.zero
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    if bounds.size != lastSize {
      lastSize = bounds.size
      metalDepthTexture = makeDepthTexture()
    }
  }
  
  // MARK: - Private
  
  private func render(time: CFTimeInterval) {
    guard let depth = metalDepthTexture, let drawable = metalLayer.nextDrawable() else {
      return
    }

    let delta = time - lastUpdateTime
    if delta >= preferredTimeBetweenUpdates {
      updateLoop(delta)
      lastUpdateTime = time

      scene.setContent(
        content(),
        shaderLibrary: shaderLibrary,
        geometryLibrary: geometryLibrary,
        surfaceAspect: Float(layer.frame.size.width / layer.frame.size.height)
      )
    }

    // Update command values for GPU & Time (primarily used for transitions)
    scene.commands.forEach { (command, previousStorage) in
      command.storage.update(time: time, command: command, previous: previousStorage)
    }

    renderer.render(time, layerDrawable: drawable, depthTexture: depth, commands: scene.commands)
  }
  
  private func makeDepthTexture() -> MTLTexture? {
    let metalLayer = metalLayer
    
    var drawableSize = metalLayer.drawableSize
    
    if drawableSize == .zero {
      drawableSize = metalLayer.preferredFrameSize()
      drawableSize.width *= metalLayer.contentsScale
      drawableSize.height *= metalLayer.contentsScale
    }
    
    assert(drawableSize != .zero, "Unaccounted situtation")
    
    let desc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .depth32Float_stencil8,
        width: Int(drawableSize.width),
        height: Int(drawableSize.height),
        mipmapped: false
    )
    desc.storageMode = .private
    desc.usage = .renderTarget
    
    return device.makeTexture(descriptor: desc)
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
