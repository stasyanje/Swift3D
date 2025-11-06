//
//  Node.swift
//  
//
//  Created by Andrew Zimmer on 1/21/23.
//

import Foundation

public protocol PrintableNode {
  var printedTree: [String] { get }
}

public protocol DrawableNode {
  var drawCommands: [MetalDrawable] { get }
}

public protocol Node: DrawableNode, PrintableNode {
  associatedtype Body: Node
  @SceneBuilder @MainActor var body: Body { get }
}

// MARK: - Defaults

extension Node {
  public var body: some Node {
    self
  }

  @MainActor public var drawCommands: [MetalDrawable] {
    body.drawCommands
  }
}

public extension PrintableNode {
  var printedTree: [String] {
    ["\(self):\(String(describing:type(of: self)))"]
  }
}
