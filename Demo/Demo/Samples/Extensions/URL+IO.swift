//
//  URL+IO.swift
//  Intro
//
//  Created by Andrew Zimmer on 2/10/23.
//

import Foundation

extension URL {
  static func resource(at path: String) -> URL {
    var components = URLComponents()
    components.path = path
    let url = components.url!
    
    return Bundle.main.url(
      forResource: url.deletingPathExtension().lastPathComponent,
      withExtension: url.pathExtension
    )!
  }
}
