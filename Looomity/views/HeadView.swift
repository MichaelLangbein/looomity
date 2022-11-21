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
        let roll = Float(truncating: observation.roll!) + Float.pi / 2.0
        let pitch = Float(truncating: observation.pitch!)
        let yaw = Float(truncating: observation.yaw!)
        let leftImg = Float(observation.boundingBox.minX)
        let rightImg = Float(observation.boundingBox.maxX)
        let topImg = Float(observation.boundingBox.maxY)
        let bottomImg = Float(observation.boundingBox.minY)

        // SceneView
        self.sceneView.frame = CGRect(x: 0, y: 0, width: self.imageSize.width, height: self.imageSize.height)
        
        // Scene
        let scene = SCNScene()
        
        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false
        camera.projectionDirection = imageSize.width > imageSize.height ? .horizontal : .vertical
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        // head-positioning only seems to work with camera at 0/0/0.
        // did I forget to un-apply the view-matrix?
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        
        self.sceneView.pointOfView = cameraNode
        
        // Size of face in meters
        let w: Float = 0.165
        let h: Float = 0.17
        
        let cWorld = getHeadPosition(
            w: w, h: h, ar: Float(imageSize.width) / Float(imageSize.height),
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
        camera.technique = SCNTechnique.init(dictionary: [
            "passes": [
                "color2alpha", [
                    "draw": "DRAW_QUAD",
                    "program": "color2alpha",
                    "inputs": [
                        "colorSampler": "COLOR",
                        "a_position": "a_position-symbol"
                    ]
                ]
            ],
            "sequence": ["color2alpha"],
            "symbols": [
                "a_position-symbol": "vertex"
            ]
        ])
        // Resoures placed at:
        // https://developer.apple.com/documentation/bundleresources/placing_content_in_a_bundle
        
        
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

/**
 * I have that strange problem of the head being placed sideways.
 * My suspicion is that this is because the camera looks at the scene vertically.
 * I hope to fix the problem by first making sure that the image and the 3d-scene cover the exact same frame
 */

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
        let ar = size.width / size.height
        let uiWidth = UIScreen.main.bounds.width
        let w = 0.8 * uiWidth
        let h = w / ar
        
        return ZStack {
            
            Image(uiImage: img!)
                .resizable()
                .scaledToFit()
                .border(.green)
            
            HeadView(observation: observation, imageSize: size) { renderer, sceneView in
                    print("rendering ...")
                }
                .border(.red)
            
        }.frame(width: w, height: h)
    }
}
