//
//  HeadView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit



struct HeadView : UIViewRepresentable {
    
    // Parameters for a detected face
    var observation: VNFaceObservation
    // Aspect-ratio of underlying photo
    var imageSize: CGSize
    // Called after each rendered frame
    var onRender: ((SCNSceneRenderer, SCNView) -> Void)?
    
    // Needs to remain in scope
    let sceneView = SCNView()

    func makeUIView(context: Context) -> SCNView {
        // Having swiftui connect scene-view with the coordinator
        self.sceneView.delegate = context.coordinator
        
        // Unwrapping face-detection parameters
        let roll = Float(truncating: observation.roll!)
        let pitch = Float(truncating: observation.pitch!)
        let yaw = Float(truncating: observation.yaw!)
        let leftImg = Float(observation.boundingBox.minX)
        let rightImg = Float(observation.boundingBox.maxX)
        let topImg = Float(observation.boundingBox.maxY)
        let bottomImg = Float(observation.boundingBox.minY)

        // Scene
        let scene = SCNScene()

        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        cameraNode.camera = camera

        // Size of head in meters
        let w: Float = 0.25
        
        // aspect-ratio's
        let arImg = Float(imageSize.width / imageSize.height)
        let sceneFrame = self.sceneView.frame
        let arCam = Float(sceneFrame.width / sceneFrame.height)
        
        let cWorld = getHeadPosition(
            w: w,
            arImg: arImg, arCam: arCam,
            topImg: topImg, rightImg: rightImg, bottomImg: bottomImg, leftImg: leftImg,
            projectionTransform: camera.projectionTransform, viewTransform: SCNMatrix4Invert(cameraNode.transform)
        )
        
        // ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "Light"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)

        // loading model
        guard let loadedScene = SCNScene(named: "Loomis_Head.usdz") else {
            return SCNView()
        }
        let figure = loadedScene.rootNode
        
        // make white transparent for background,
        // while still obscuring model elements
         applyCustomShader(figure)
//        let postprocessor = SCNTechnique(dictionary: [
//            "passes": [
//                "draw": "DRAW_SCENE",
//                "program": "whiteToTransparent"
//            ]
//        ])
        
        // scaling and repositioning
        figure.scale = SCNVector3(
            x: w / figure.boundingSphere.radius,
            y: w / figure.boundingSphere.radius,
            z: w / figure.boundingSphere.radius
        )
        figure.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
        figure.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
        figure.name = "Head"
        scene.rootNode.addChildNode(figure)

        // scene
        self.sceneView.scene = scene
        self.sceneView.allowsCameraControl = true
        self.sceneView.cameraControlConfiguration.allowsTranslation = true
        self.sceneView.backgroundColor = UIColor.clear
        return self.sceneView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        print("Update called")
    }
    
    // allowing user to hook into render loop
    func makeCoordinator() -> RenderDelegate {
        return RenderDelegate(parent: self)
    }
    final class RenderDelegate: NSObject, SCNSceneRendererDelegate {
        var parent: HeadView
        init(parent: HeadView) {
            self.parent = parent
        }
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            if let callback = self.parent.onRender {
                callback(renderer, parent.sceneView)
            }
        }
    }
}



struct HeadView_Previews: PreviewProvider {
    static var previews: some View {
        let observation = VNFaceObservation(
            requestRevision: 0,
            boundingBox: CGRect(x: 0.4, y: 0.75, width: 0.125, height: 0.125),
            roll: 0.3,
            yaw: 0.01,
            pitch: -0.3
        )
        
        let img = UIImage(named: "TestImage")
        let size = img!.size
        
        return ZStack {
            Image(uiImage: img!)
                .resizable()
                .scaledToFit()
                .border(.green)
            HeadView(observation: observation, imageSize: size) { renderer, sceneView in
                print("rendering ...")
            }.border(.red)
        }.frame(width: 0.9 * size.width, height: 0.9 * size.height)
    }
}
