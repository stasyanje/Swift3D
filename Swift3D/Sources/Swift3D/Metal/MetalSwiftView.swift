//
//  MetalSwiftView.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import UIKit
import SwiftUI

// Swift3DView + EquatableView

public typealias Swift3DView = EquatableView<FreeSwift3DView>

public extension Swift3DView {
  init(
    preferredFps: Int = 30,
    updateLoop: ((_ deltaTime: Double) -> Void)? = nil,
    @SceneBuilder _ content: @escaping () -> any Node
  ) {
    self.init(
      content: FreeSwift3DView(
        preferredFps: preferredFps,
        updateLoop: updateLoop,
        content
      )
    )
  }
}

// Prefer Swift3DView over inequtable view

public struct FreeSwift3DView: UIViewRepresentable, Equatable {
  let id = UUID()
  let updateLoop: ((_ deltaTime: Double) -> Void)?
  let preferredFps: Int
  let content: () -> any Node
  
  public init(
    preferredFps: Int,
    updateLoop: ((_ deltaTime: Double) -> Void)?,
    @SceneBuilder _ content: @escaping () -> any Node
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
    print("updateUIView \(context)")
  }
}
