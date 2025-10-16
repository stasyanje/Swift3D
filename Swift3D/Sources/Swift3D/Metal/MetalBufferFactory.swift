import Foundation
import Metal
import MetalKit
import UIKit
import simd

final class MetalBufferFactory {
  let device: MTLDevice
  
  init(device: MTLDevice) {
    self.device = device
  }
  
  func buffer<Data>(storing data: Data) -> MTLBuffer {
    let buffer = device.makeBuffer(length: MemoryLayout<Data>.size)!
    buffer.contents().storeBytes(of: data, as: Data.self)
    return buffer
  }
  
  func texture(from image: CGImage, flip: Bool = false) -> MTLTexture {
    let bytesPerPixel = 4
    let bitsPerComponent = 8
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let rowBytes = image.width * bytesPerPixel
    
    let context = CGContext(data: nil,
                            width: image.width,
                            height: image.height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: rowBytes,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = context else {
      fatalError()
    }
    
    context.clear(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    
    if flip {
      context.translateBy(x: 0, y: CGFloat(image.height))
      context.scaleBy(x: 1.0, y: -1.0)
    }
    
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: MTLPixelFormat.rgba8Unorm,
      width: image.width,
      height: image.height,
      mipmapped: false)
    
    guard let texture = device.makeTexture(descriptor: descriptor),
          let pixelData = context.data else {
      fatalError()
    }
    
    let region = MTLRegionMake2D(0, 0, image.height, image.height)
    texture.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: rowBytes)
    
    return texture
  }
  
  func texture(from color: simd_float4) -> MTLTexture {
    let descriptor = MTLTextureDescriptor()
    descriptor.width = 8
    descriptor.height = 8
    descriptor.mipmapLevelCount = 1
    descriptor.storageMode = .shared
    descriptor.arrayLength = 1
    descriptor.sampleCount = 1
    descriptor.cpuCacheMode = .writeCombined
    descriptor.allowGPUOptimizedContents = false
    descriptor.pixelFormat = .rgba8Unorm
    descriptor.textureType = .type2D
    descriptor.usage = .shaderRead
    
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      fatalError()
    }
    
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let size = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
    let region = MTLRegion(origin: origin, size: size)
    let mappedColor = simd_uchar4(color * 255)
    
    Array<simd_uchar4>(repeating: mappedColor, count: 64).withUnsafeBytes { ptr in
      texture.replace(region: region, mipmapLevel: 0, withBytes: ptr.baseAddress!, bytesPerRow: 32)
    }
    
    return texture
  }

  // I went ahead and used metalkit here. I was initially doing things without the kit, but
  // I've already got plenty texture loading code in here after all.
  func cubeTexture(image: UIImage) -> MTLTexture  {
    let loader = MTKTextureLoader(device: device)
    let cubeTextureOptions: [MTKTextureLoader.Option : Any] = [
      .textureUsage : MTLTextureUsage.shaderRead.rawValue,
      .textureStorageMode : MTLStorageMode.private.rawValue,
      .generateMipmaps : true,
      .cubeLayout : MTKTextureLoader.CubeLayout.vertical,
    ]

    let data = image.pngData()!
    do {
      let texture = try loader.newTexture(data: data, options: cubeTextureOptions)
      return texture
    } catch {
      print("error:\(error)")
      fatalError()
    }
  }
  
  func depthTexture(drawableSize: CGSize) -> MTLTexture {
    let desc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .depth32Float_stencil8,
        width: Int(drawableSize.width),
        height: Int(drawableSize.height),
        mipmapped: false
    )
    desc.storageMode = .private
    desc.usage = .renderTarget
    
    return device.makeTexture(descriptor: desc)!
  }
}
