//
//  HeadView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit


/**
  Photo-space: [0, 1]^2
    ^
    |  2 * is - 1
    V
  Screen-space: [-1, 1]^3
    ^
    | Projection-matrix
    V
  Camera-object-space
    ^
    |  View-matrix
    V
  World-space: [-infty, infty]^3
    ^
    | Model-matrix
    V
  Model-space: ... depends on model ...
 */


func imageSpaceToScreenSpace() {
    
}

struct HeadView : UIViewRepresentable {
    var observation: VNFaceObservation
    var onRender: ((SCNSceneRenderer, SCNView) -> Void)?
    
    // needs to remain in scope
    let sceneView = SCNView()

    func makeUIView(context: Context) -> SCNView {
        // having swiftui connect scene-view with the coordinator
        self.sceneView.delegate = context.coordinator
        
        // SceneKit coordinates:
        // x = right
        // y = up
        // z = out of screen
        
        // Unwrapping parameters
        let roll = Float(truncating: observation.roll!)
        let pitch = Float(truncating: observation.pitch!)
        let yaw = Float(truncating: observation.yaw!)
        let x = 2.0 * Float(observation.boundingBox.minX + observation.boundingBox.width / 2.0) - 1.0
        let y = 2.0 * Float(observation.boundingBox.minY + observation.boundingBox.height / 2.0) - 1.0
        let scale = 2.0 * Float(observation.boundingBox.width)

        // scene
        let scene = SCNScene()
        
        // camera
        let cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = 10
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))

        
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
        figure.scale = SCNVector3(x: scale / figure.boundingSphere.radius, y: scale / figure.boundingSphere.radius, z: scale / figure.boundingSphere.radius)
        figure.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
        figure.position = SCNVector3(x: x, y: y, z: 0)
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



func applyCustomShader(_ node: SCNNode) {
    node.geometry?.firstMaterial?.transparencyMode = .aOne
    node.geometry?.shaderModifiers = [
        SCNShaderModifierEntryPoint.fragment : """
            #pragma transparent
            #pragma body
            float whiteness = (_output.color.r + _output.color.g + _output.color.b) / 3.0;
            // both rgb and a range from 0 to 1
            // a = 0.0: transparent
            // a = 1.0: opaque
            _output.color.a = 1.0 - whiteness;
        """
    ]
    for child in node.childNodes {
        applyCustomShader(child)
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
        return ZStack {
            Image("TestImage")
                .resizable()
                .scaledToFit()
                .border(.green)
            HeadView(observation: observation) { renderer, sceneView in
                print("rendering ...")
            }
                .border(.red)
        }.frame(width: 350, height: 470)
    }
}
