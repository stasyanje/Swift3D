//
//  MetalSwiftView.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import SwiftUI

// Swift3DView + EquatableView

public typealias Swift3DView = EquatableView<FreeSwift3DView>

public extension Swift3DView {
  init(
    preferredFps: Int = 30,
    updateLoop: MetalView.Update? = nil,
    @SceneBuilder contentFactory: @escaping MetalView.ContentFactory
  ) {
    self.init(
      content: FreeSwift3DView(
        preferredFps: preferredFps,
        updateLoop: updateLoop,
        contentFactory
      )
    )
  }
}

// Prefer Swift3DView over inequtable view

public struct FreeSwift3DView: UIViewRepresentable, Equatable {  
  // MARK: - State
  
  let id = UUID()
  let updateLoop: MetalView.Update?
  let preferredFps: Int
  let content: MetalView.ContentFactory
  
  init(
    preferredFps: Int,
    updateLoop: MetalView.Update?,
    @SceneBuilder _ content: @escaping MetalView.ContentFactory
  ) {
    self.updateLoop = updateLoop
    self.preferredFps = preferredFps
    self.content = content
  }
  
  // MARK: - Equatable
  
  public static func == (lhs: FreeSwift3DView, rhs: FreeSwift3DView) -> Bool {
    lhs.id == rhs.id && lhs.preferredFps == rhs.preferredFps
  }
  
  // MARK: - UIViewRepresentable

  public func makeUIView(context: Context) -> MetalView {
    do {
      return try MetalView(
        preferredFps: preferredFps,
        updateLoop: updateLoop ?? { _ in },
        contentFactory: content
      )
    } catch {
      fatalError(String(describing: error))
    }
  }

  public func updateUIView(_ uiView: MetalView, context: Context) {
    // TODO: pass preferredFps
  }
}
