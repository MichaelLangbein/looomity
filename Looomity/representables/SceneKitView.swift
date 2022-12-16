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
    // Should default camera-control be active?
    var defaultCameraControl: Bool
    // Called on each frame
    var onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)?
    // Called on tap
    var onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    // Called on pan
    var onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    // Called on pinch
    var onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    // Called on swipe
    var onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    // Called on rotate
    var onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    //---------------- SCNView --------------------------------------//
    // Handle to SCNView
    var sceneView: SCNView?
    
    init(
        width: Int, height: Int,
        loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])? = nil,
        nodes: [SCNNode] = [],
        renderContinuously: Bool = false,
        defaultCameraControl: Bool = false,
        onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)? = nil,
        onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil
    ) {
        self.width = width
        self.height = height
        self.loadNodes = loadNodes
        self.nodes = nodes
        self.renderContinuously = renderContinuously
        self.defaultCameraControl = defaultCameraControl
        self.onRender = onRender
        self.onTap = onTap
        self.onPan = onPan
        self.onPinch = onPinch
        self.onSwipe = onSwipe
        self.onRotate = onRotate
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
        // Otherwise overwritten by on<Gesture> methods
         sceneView.allowsCameraControl = defaultCameraControl
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
        let panRecognizer    = UIPanGestureRecognizer(      target: self, action: #selector(handlePan(panGesture:))       )
        let tapRecognizer    = UITapGestureRecognizer(      target: self, action: #selector(handleTap(tapGesture:))       )
        let pinchRecognizer  = UIPinchGestureRecognizer(    target: self, action: #selector(handlePinch(pinchGesture:))   )
        let swipeRecognizer  = UISwipeGestureRecognizer(    target: self, action: #selector(handleSwipe(swipeGesture:))   )
        let rotateRecognizer = UIRotationGestureRecognizer( target: self, action: #selector(handleRotate(rotateGesture:)) )
        tapRecognizer.delegate = self
        panRecognizer.delegate = self
        pinchRecognizer.delegate = self
        swipeRecognizer.delegate = self
        rotateRecognizer.delegate = self
        sceneView.addGestureRecognizer(panRecognizer)
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.addGestureRecognizer(pinchRecognizer)
        sceneView.addGestureRecognizer(swipeRecognizer)
        sceneView.addGestureRecognizer(rotateRecognizer)
        
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
        guard let onPan = self.onPan else { return }
        let view = self.sceneView!
        onPan(panGesture, view, self.nodes)
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        guard let onTap = self.onTap else { return }
        let view = self.sceneView!
        onTap(tapGesture, view, self.nodes)
    }
    
    @objc func handlePinch(pinchGesture: UIPinchGestureRecognizer) {
        guard let onPinch = self.onPinch else { return }
        let view = self.sceneView!
        onPinch(pinchGesture, view, self.nodes)
    }
    
    @objc func handleSwipe(swipeGesture: UISwipeGestureRecognizer) {
        guard let onSwipe = self.onSwipe else { return }
        let view = self.sceneView!
        onSwipe(swipeGesture, view, self.nodes)
    }
    
    @objc func handleRotate(rotateGesture: UIRotationGestureRecognizer) {
        guard let onRotate = self.onRotate else { return }
        let view = self.sceneView!
        onRotate(rotateGesture, view, self.nodes)
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
    // Shoule default-camera-control be used?
    var defaultCameraControl = false
    // Called on each frame
    var onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)?
    // Called on gestures
    var onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    
    func makeUIViewController(context: Context) -> SceneController {
        return SceneController(
            width: width,
            height: height,
            loadNodes: loadNodes,
            nodes: nodes,
            renderContinuously: renderContinuously,
            defaultCameraControl: defaultCameraControl,
            onRender: onRender,
            onTap: onTap,
            onPan: onPan,
            onPinch: onPinch,
            onSwipe: onSwipe,
            onRotate: onRotate
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
            onTap: { gesture, view, nodes in
                let hits = getGestureHits(view: view, gesture: gesture)
                guard let node = hits.first else { return }
//                node.addAnimation(createPopAnimation(), forKey: "MyBounceAnimation")
                node.addAnimation(createOpacityHideAnimation(), forKey: "disappear")
            },
            onPan: { gesture, view, nodes in
                
            }
        )
    }
}
