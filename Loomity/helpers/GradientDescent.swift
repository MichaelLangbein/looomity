//
//  GradientDescent.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import Vision
import SceneKit


func gradientDescent(sceneView: SCNView, observation: VNFaceObservation) {
    // @TODO
}


func sse(sceneView: SCNView, observation: VNFaceObservation) -> Float {
    guard let scene = sceneView.scene else { return 0.0 }
    
    // get important points from model
    let head = scene.rootNode.childNode(withName: "Head", recursively: true)!
    let leftEye = head.childNode(withName: "LeftEye", recursively: true)!
    let rightEye = head.childNode(withName: "RightEye", recursively: true)!
    let nose = head.childNode(withName: "Nose", recursively: true)!

    // project those points
    let leftEyeProjected = sceneView.projectPoint(leftEye.position)
    let rightEyeProjected = sceneView.projectPoint(rightEye.position)
    let noseProjected = sceneView.projectPoint(nose.position)

    // get important points from image
    let landmarks = observation.landmarks!
    let leftEyeTarget = landmarks.leftEye!.normalizedPoints[0]
    let rightEyeTarget = landmarks.rightEye!.normalizedPoints[0]
    let noseTarget = landmarks.nose!.normalizedPoints[0]

    // compare projected points with face-landmarks
    let s = (
          vectorDiff(leftEyeProjected, leftEyeTarget)
        + vectorDiff(rightEyeProjected, rightEyeTarget)
        + vectorDiff(noseProjected, noseTarget)
    )
    return s
}

private func vectorDiff(_ v1: SCNVector3, _ v2: CGPoint) -> Float {
    return pow(v1.x - Float(v2.x), 2.0) + pow(v1.y - Float(v2.y), 2.0)
}

func applyDelta(sceneView: SCNView, deltaX: Float, deltaY: Float, deltaScale: Float, deltaYaw: Float, deltaRoll: Float, deltaPitch: Float) {
    guard let scene = sceneView.scene else { return }
    
    let head = scene.rootNode.childNode(withName: "Head", recursively: true)!
    head.position = SCNVector3(
        x: head.position.x + deltaX,
        y: head.position.y + deltaY,
        z: 0
    )
    head.eulerAngles = SCNVector3(
        x: head.eulerAngles.x + deltaPitch,
        y: head.eulerAngles.y + deltaYaw,
        z: head.eulerAngles.z + deltaRoll
    )
    head.scale = SCNVector3(
        x: 1.0 + deltaScale,
        y: 1.0 + deltaScale,
        z: 1.0 + deltaScale
    )
}
