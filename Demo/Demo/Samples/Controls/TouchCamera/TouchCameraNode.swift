//
//  CameraControlelr.swift
//  Swift3D
//
//  Created by Andrew Zimmer on 2/2/23.
//

import Swift3D

struct TouchCameraNode: Node {
  var id: String { "Camera Controller" }

  let controller: TouchCameraController
  let skybox: MetalDrawable_Shader

  init(controller: TouchCameraController, skybox: MetalDrawable_Shader) {
    self.controller = controller
    self.skybox = skybox
  }

  var body: some Node {
    CameraNode(
      id: "Main Camera",
      transform: controller.transform,
      skyboxShader: skybox
    )
  }
}


