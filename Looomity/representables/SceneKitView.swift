//
//  SceneKitView.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI
import SceneKit


class SceneController: UIViewController, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {
    
    //---------------- Inputs -------------------------------------//
    // Dimensions
    var width: Int
    var height: Int
    // Provide nodes as function of scene, camera
    var loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])?
    // Provide nodes directly
    var nodes: [SCNNode]
    // Should rendering continue when no action is going on?
    var renderContinuously: Bool
    // Called on each frame
    var onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)?
    // Called on tap
    var onTap: ((SCNNode, SCNView, [SCNNode]) -> Void)?
    //---------------- SCNView --------------------------------------//
    // Handle to SCNView
    var sceneView: SCNView?
    //---------------- Gesture-states -------------------------------//
    var panStartZ: CGFloat = 0.0
    var lastPanLocation: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)
    var draggingNode: SCNNode?
    
    
    init(
        width: Int, height: Int,
        loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])? = nil,
        nodes: [SCNNode] = [],
        renderContinuously: Bool = false,
        onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)? = nil,
        onTap: ((SCNNode, SCNView, [SCNNode]) -> Void)? = nil
    ) {
        self.width = width
        self.height = height
        self.loadNodes = loadNodes
        self.nodes = nodes
        self.renderContinuously = renderContinuously
        self.onRender = onRender
        self.onTap = onTap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sceneView = makeSceneView()
        self.view = sceneView
        self.sceneView = sceneView
    }
    
    func makeSceneView() -> SCNView {
        
        let sceneView = SCNView()
        // Having swiftui connect scene-view with the coordinator
        sceneView.delegate = self
        // Probably not required - we can just set animations.
        sceneView.rendersContinuously = self.renderContinuously
        // Ambient light
        sceneView.autoenablesDefaultLighting = true
        // Background
        sceneView.backgroundColor = UIColor.clear
        // We *won't* activate camera-control. Gestures shall move objects, not the camera.
        // self.sceneView.allowsCameraControl = true
        // Size
        sceneView.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        
        // Scene
        let scene = SCNScene()
        sceneView.scene = scene
        
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
        sceneView.pointOfView = cameraNode
        
        // Gesture recognizers
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(tapGesture:)))
        tapRecognizer.delegate = self
        panRecognizer.delegate = self
        sceneView.addGestureRecognizer(panRecognizer)
        sceneView.addGestureRecognizer(tapRecognizer)
        
        // adding user-defined nodes
        if let load = self.loadNodes {
            self.nodes = load(sceneView, scene, camera)
        }
        for node in self.nodes {
            scene.rootNode.addChildNode(node)
        }
        
        return sceneView
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let onRender = self.onRender {
            onRender(renderer, self.sceneView!, self.nodes)
        }
    }
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        let view = self.sceneView!
        let location = panGesture.location(in: view)
        switch panGesture.state {
            case .began:
                guard let hitNodeResult = view.hitTest(location, options: nil).first else { return }
                // panStartZ and draggingNode should be defined in the containing class
                panStartZ = CGFloat(view.projectPoint(lastPanLocation).z)
                draggingNode = hitNodeResult.node
            case .changed:
                let location = panGesture.location(in: view)
                let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ))
                draggingNode?.worldPosition = worldTouchPosition
            default:
                break
        }
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        let view = self.sceneView!
        let location = tapGesture.location(in: view)
        guard let hitNodeResult = view.hitTest(location, options: nil).first else { return }
        guard let onTap = self.onTap else { return }
        onTap(hitNodeResult.node, view, self.nodes)
    }
}



struct SceneKitView: UIViewControllerRepresentable {
    
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

    // @TODO: Needs to remain in scope?
    let sceneView = SCNView()
    
    func makeUIViewController(context: Context) -> SceneController {
        return SceneController(
            width: width,
            height: height,
            loadNodes: loadNodes,
            nodes: nodes,
            renderContinuously: renderContinuously,
            onRender: onRender,
            onTap: onTap
        )
    }
    
    func updateUIViewController(_ uiViewController: SceneController, context: Context) {
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
//                nodes[1].position.x += 0.01
            },
            onTap: { node, view, nodes in
//                let animation = CABasicAnimation(keyPath: "scale")
//                animation.fromValue = SCNVector3(x: 1, y: 1, z: 1)
//                animation.toValue = SCNVector3(x: 1.2, y: 1.2, z: 1.2)
                let animation = CAKeyframeAnimation(keyPath: "scale")
                animation.duration = 0.2
                animation.keyTimes = [
                    NSNumber(value: 0),
                    NSNumber(value: 0.1 * animation.duration),
                    NSNumber(value: 0.5 * animation.duration),
                    NSNumber(value: animation.duration)
                ]
                animation.values = [
                    SCNVector3(x: 1, y: 1, z: 1),
                    SCNVector3(x: 1.3, y: 1.3, z: 1.3),
                    SCNVector3(x: 0.8, y: 0.8, z: 0.8),
                    SCNVector3(x: 1, y: 1, z: 1),
                ]
                animation.repeatCount = 1
                animation.autoreverses = false
                animation.isRemovedOnCompletion = true
                node.addAnimation(animation, forKey: nil)
            }
        )
    }
}
