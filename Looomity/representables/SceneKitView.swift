//
//  SceneKitView.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI
import SceneKit


struct SceneKitView: UIViewRepresentable {

    // Dimensions
    var width: Int
    var height: Int
    // Provide nodes as function of scene, camera
    var loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])
    // Provide nodes directly
    @State var nodes: [SCNNode] = []
    // Should rendering continue when no action is going on?
    var renderContinuously = false
    // Called on each frame
    var onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)?
    // Called on tap
    var onTap: ((SCNNode, SCNView, [SCNNode]) -> Void)?


    // Needs to remain in scope
    let sceneView = SCNView()


    func makeUIView(context: Context) -> SCNView {
        
        // Having swiftui connect scene-view with the coordinator
        self.sceneView.delegate = context.coordinator
        // Probably not required - we can just set animations.
        self.sceneView.rendersContinuously = self.renderContinuously
        // Ambient light
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.backgroundColor = UIColor.clear
        // We *won't* activate camera-control. Gestures shall move objects, not the camera.
        // self.sceneView.allowsCameraControl = true
        
        // SceneView
        self.sceneView.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        
        // Scene
        let scene = SCNScene()
        self.sceneView.scene = scene
        
        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false
        camera.projectionDirection = width > height ? .horizontal : .vertical
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        self.sceneView.pointOfView = cameraNode
        
        // Create the gesture recognizers
        let gestureDelegate = GestureDelegate(parent: self)
        let panRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(gestureDelegate.handlePan(panGesture:))
        )
        self.sceneView.addGestureRecognizer(panRecognizer)
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(gestureDelegate.handleTap(tapGesture:))
        )
        self.sceneView.addGestureRecognizer(tapRecognizer)
        
        // adding user-defined nodes
        let nodes = self.loadNodes(self.sceneView, scene, camera)
        for node in nodes {
            scene.rootNode.addChildNode(node)
        }
        self.nodes = nodes
        
        return self.sceneView
    }
    
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        print("Update called")
    }
    
    
    // allowing user to hook into render loop
    func makeCoordinator() -> RenderDelegate {
        return RenderDelegate(parent: self)
    }
    
}

final class GestureDelegate: NSObject {
    
    // reference to parent
    var parent: SceneKitView
    // pan-state
    var draggingNode: SCNNode?
    var panStartZ: CGFloat?
    var lastPanLocation: SCNVector3?
    
    init(parent: SceneKitView) {
        self.parent = parent
    }

    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        let view = parent.sceneView
        let location = panGesture.location(in: view)
        switch panGesture.state {
            case .began:
                guard let hitNodeResult = view.hitTest(location, options: nil).first else { return }
                // panStartZ and draggingNode should be defined in the containing class
                panStartZ = CGFloat(view.projectPoint(lastPanLocation!).z)
                draggingNode = hitNodeResult.node
            case .changed:
                let location = panGesture.location(in: view)
                let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))
                draggingNode?.worldPosition = worldTouchPosition
            default:
                break
        }
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        let view = parent.sceneView
        let location = tapGesture.location(in: view)
        guard let hitNodeResult = view.hitTest(location, options: nil).first else { return }
        guard let onTap = parent.onTap else { return }
        onTap(hitNodeResult.node, view, parent.nodes)
        // @TODO: handle tap&drag === rotate
    }
}

final class RenderDelegate: NSObject, SCNSceneRendererDelegate {
    var parent: SceneKitView
    init(parent: SceneKitView) {
        self.parent = parent
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let onRender = self.parent.onRender {
            onRender(renderer, parent.sceneView, parent.nodes)
        }
    }
}

struct SceneKitView_Previews: PreviewProvider {
    static var previews: some View {
        
        let plane = SCNNode(geometry: SCNPlane(width: 2.0, height: 1.0))
        plane.position = SCNVector3(x: 0.1, y: 0.2, z: -1.0)
        plane.geometry!.firstMaterial!.diffuse.contents  = UIColor(red: 30.0 / 255.0, green: 150.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        
        let bx = SCNNode(geometry: SCNBox(width: 0.2, height: 0.3, length: 0.2, chamferRadius: 0.05))
        bx.geometry!.firstMaterial!.diffuse.contents  = UIColor(red: 125.0 / 255.0, green: 10.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        bx.position = SCNVector3(x: -0.5, y: 0.1, z: -0.1)
        
        return SceneKitView(
            width: 400, height: 600,
            loadNodes: { view, scene, camera in
                return [plane, bx]
            },
            onRender: { renderer, view, nodes in
                nodes[1].position.x += 0.01
            },
            onTap: { node, view, nodes in
                node.position.x += 0.01
            }
        )
    }
}
