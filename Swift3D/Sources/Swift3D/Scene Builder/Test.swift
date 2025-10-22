//
//  File.swift
//  
//
//  Created by Andrew Zimmer on 1/20/23.
//

import Foundation



func makeCode(@SceneBuilder _ content: () -> any Node) -> any Node {
  content()
}

public struct SceneBuilderTest {
  public static func testBuilder() {
    // let yes = true
    // let no = false

    let tree = makeCode {

      ForEach3D(data: ["one", "two", "three"]) { element in
        GeometryNode(id: element, shape: .triangle)
      }

      GroupNode(id: "one") {
        GeometryNode(id: "tri1", shape: .triangle)
      }
      GeometryNode(id: "tris", shape: .triangle)
    }

    print("\n")
    print(tree)
    print("\n")
    print(tree.printedTree.reduce("", { partialResult, str in
      partialResult + "\n" + str
    }))
  }
}


