//
//  MetalSwiftView.swift
//  
//
//  Created by Andrew Zimmer on 1/18/23.
//

import UIKit
import SwiftUI

public struct Swift3DView: UIViewRepresentable {
  let updateLoop: ((_ deltaTime: Double) -> Void)?
  let preferredFps: Int
  let content: () -> any Node
  
  public init(
    preferredFps: Int = 30,
    updateLoop: ((_ deltaTime: Double) -> Void)? = nil,
    @SceneBuilder _ content: @escaping () -> any Node
  ) {
    self.updateLoop = updateLoop
    self.preferredFps = preferredFps
    self.content = content
  }

  public func makeUIView(context: Context) -> UIView {
    do {
      return try MetalView(
        preferredFps: preferredFps,
        updateLoop: updateLoop ?? { _ in },
        contentFactory: content
      )
    } catch {
      assertionFailure(String(describing: error))
      let errorLabel = UILabel()
      errorLabel.text = error.localizedDescription
      errorLabel.sizeToFit()
      return errorLabel
    }
  }

  public func updateUIView(_ uiView: UIView, context: Context) {}
}
