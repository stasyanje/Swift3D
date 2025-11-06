//
//  ForEach.swift
//  
//
//  Created by Andrew Zimmer on 2/14/23.
//

import Foundation

public struct ForEach3D<Data: RandomAccessCollection, Content: Node>: Node {
  var data: Data
  var content: (Data.Element) -> Content
  
  // MARK: - Node
  
  public var printedTree: [String] {
    data.flatMap {
      content($0).printedTree
    }
  }

  public var drawCommands: [MetalDrawable] {
    data.flatMap {
      content($0).drawCommands
    }
  }
}

extension ForEach3D where Data.Element: Identifiable {
    public init(_ data: Data, @SceneBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
}

extension ForEach3D where Data == Range<Int> {
    public init(_ data: Range<Int>, @SceneBuilder content: @escaping (Int) -> Content) {
        self.data = data
        self.content = content
    }
}
