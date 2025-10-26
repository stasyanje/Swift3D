//
//  CameraControlelr.swift
//  Swift3D
//
//  Created by Andrew Zimmer on 2/2/23.
//

import Swift3D

struct TouchCameraNode<Skybox: MetalDrawable_Shader>: Node {
  var id: String { "Camera Controller" }

  let controller: TouchCameraController
  let skybox: Skybox

  init(controller: TouchCameraController, skybox: Skybox = .skybox()) {
    self.controller = controller
    self.skybox = skybox
  }

  var body: some Node {
    CameraNode(id: "Main Camera")
      .skybox(skybox)
      .transform(controller.transform)
      .transition(.easeInOut(0.3))
  }
}


