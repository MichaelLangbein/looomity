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
    var screen_width: CGFloat
    var screen_height: CGFloat
    var image_width: CGFloat
    var image_height: CGFloat
    
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
    // Called on two-finger-pan
    var onDoublePan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)?
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
        screen_width: CGFloat, screen_height: CGFloat,
        image_width: CGFloat, image_height: CGFloat,
        loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])? = nil,
        nodes: [SCNNode] = [],
        renderContinuously: Bool = false,
        defaultCameraControl: Bool = false,
        onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)? = nil,
        onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onDoublePan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil,
        onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil
    ) {
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.image_width = image_width
        self.image_height = image_height
        self.loadNodes = loadNodes
        self.nodes = nodes
        self.renderContinuously = renderContinuously
        self.defaultCameraControl = defaultCameraControl
        self.onRender = onRender
        self.onTap = onTap
        self.onPan = onPan
        self.onDoublePan = onDoublePan
        self.onPinch = onPinch
        self.onSwipe = onSwipe
        self.onRotate = onRotate
        super.init(nibName: nil, bundle: nil)
        
        print("SceneController init")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: self.screen_width, height: self.screen_height))
        let sceneView = makeSceneView()
        sceneView.antialiasingMode = .multisampling4X
        self.view.addSubview(sceneView)
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
        sceneView.frame = CGRect(x: 0, y: 0, width: self.screen_width, height: self.screen_height)
        
        // Scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false  // using ortho-view by default now - less confusing during panning.
        camera.projectionDirection = screen_width > screen_height ? .horizontal : .vertical
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        
        let image_size_scene = CGSize(
            width: 2.0,
            height: 2.0 * image_height / image_width
        )
        let image_size_clip = fitImageIntoClip(
            width_screen: screen_width, height_screen: screen_height,
            width_img: image_width, height_img: image_height
        )
        let zCam = distanceSoCamSeesAllOfImage(
            camera: camera,
            imageSizeClip: image_size_clip,
            imageSizeScene: image_size_scene
        )
        camera.orthographicScale = 2.00
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCam)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        sceneView.pointOfView = cameraNode

        // Gesture recognisers
        let tapRecognizer    = UITapGestureRecognizer(      target: self, action: #selector(handleTap(tapGesture:))       )
        let pinchRecognizer  = UIPinchGestureRecognizer(    target: self, action: #selector(handlePinch(pinchGesture:))   )
        let swipeRecognizer  = UISwipeGestureRecognizer(    target: self, action: #selector(handleSwipe(swipeGesture:))   )
        let rotateRecognizer = UIRotationGestureRecognizer( target: self, action: #selector(handleRotate(rotateGesture:)) )
        let panRecognizer    = UIPanGestureRecognizer(      target: self, action: #selector(handlePan(panGesture:))       )
        let doublePanRecognizer = UIPanGestureRecognizer(   target: self, action: #selector(handleDoublePan(panGesture:)) )
        panRecognizer.maximumNumberOfTouches = 1
        doublePanRecognizer.minimumNumberOfTouches = 2
        doublePanRecognizer.maximumNumberOfTouches = 2
        tapRecognizer.delegate = self
        panRecognizer.delegate = self
        doublePanRecognizer.delegate = self
        pinchRecognizer.delegate = self
        swipeRecognizer.delegate = self
        rotateRecognizer.delegate = self
        self.view.addGestureRecognizer(panRecognizer)
        self.view.addGestureRecognizer(doublePanRecognizer)
        self.view.addGestureRecognizer(tapRecognizer)
        self.view.addGestureRecognizer(pinchRecognizer)
        self.view.addGestureRecognizer(swipeRecognizer)
        self.view.addGestureRecognizer(rotateRecognizer)

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
        guard
            let onRender = self.onRender,
            let view = self.sceneView
        else { return }
        onRender(renderer, view, self.nodes)
    }
    
    func translateSceneView(tx: CGFloat, ty: CGFloat) {
        guard let sv = self.sceneView else { return }
        let initialTransform = sv.transform
        sv.transform = CGAffineTransformTranslate(initialTransform, tx, ty)
    }
    
    func scaleSceneView(sx: CGFloat, sy: CGFloat) {
        guard let sv = self.sceneView else { return }
        let initialTransform = sv.transform
        sv.transform = CGAffineTransformScale(initialTransform, sx, sy)
    }
    
    public func screenshot() -> UIImage? {
        // this will save full sceneView, including white borders where the screen was bigger than the image
        guard let sceneView = self.sceneView else { return nil }
        let sceneViewImage = sceneView.snapshot()
        
        // we can crop the image like this: https://www.advancedswift.com/crop-image/
        let imageSize = fitInto(inner: CGSize(width: self.image_width, height: self.image_height), outer: sceneViewImage.size)
        let xOffset = (sceneViewImage.size.width - imageSize.width) / 2.0
        let yOffset = (sceneViewImage.size.height - imageSize.height) / 2.0
        let cropRect = CGRect(
            x: xOffset,
            y: yOffset,
            width: imageSize.width,
            height: imageSize.height
        ).integral
        guard
            let sourceCGImage = sceneViewImage.cgImage,
            let croppedCGImage = sourceCGImage.cropping(to: cropRect)
        else { return sceneViewImage }
        
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: sceneViewImage.imageRendererFormat.scale,
            orientation: sceneViewImage.imageOrientation
        )
        return croppedImage
    }
    
    public func objectOpacity(_ opacity: Double) {
        for node in nodes {
            guard let type = node.value(forKey: "type") as? String else { continue }
            if type == "figure" {
                node.opacity = opacity
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Can those two gestures be handles at the same time?
        return true
    }
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        guard
            let onPan = self.onPan,
            let view = self.sceneView
        else { return }
        onPan(panGesture, view, self.nodes)
    }
    
    @objc func handleDoublePan(panGesture: UIPanGestureRecognizer) {
        guard
            let onDoublePan = self.onDoublePan,
            let view = self.sceneView
        else { return }
        onDoublePan(panGesture, view, self.nodes)
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        guard
            let onTap = self.onTap,
            let view = self.sceneView
        else { return }
        onTap(tapGesture, view, self.nodes)
    }
    
    @objc func handlePinch(pinchGesture: UIPinchGestureRecognizer) {
        guard
            let onPinch = self.onPinch,
            let view = self.sceneView
        else { return }
        onPinch(pinchGesture, view, self.nodes)
    }
    
    @objc func handleSwipe(swipeGesture: UISwipeGestureRecognizer) {
        guard
            let onSwipe = self.onSwipe,
            let view = self.sceneView
        else { return }
        onSwipe(swipeGesture, view, self.nodes)
    }
    
    @objc func handleRotate(rotateGesture: UIRotationGestureRecognizer) {
        guard
            let onRotate = self.onRotate,
            let view = self.sceneView
        else { return }
        onRotate(rotateGesture, view, self.nodes)
    }
    
    func newNode(node: SCNNode) {
        self.nodes.append(node)
        self.sceneView?.scene?.rootNode.addChildNode(node)
        print("Added node")
    }
    
    func removeNodes(predicate: (SCNNode) -> Bool) {
        self.nodes.removeAll(where: predicate)
        guard
            let view = self.sceneView,
            let scene = view.scene
        else { return }
        for child in scene.rootNode.childNodes {
            if predicate(child) {
                child.removeFromParentNode()
            }
        }
        print("Removed nodes")
    }
    
    func toggleOrthographicView(orthographic: Bool) {
        guard let cameraNode = self.sceneView?.scene?.rootNode.childNode(withName: "Camera", recursively: true) else { return }
        cameraNode.camera?.usesOrthographicProjection = orthographic
    }
}



struct SceneKitView: UIViewControllerRepresentable {
    
    // Dimensions
    var screen_width: CGFloat
    var screen_height: CGFloat
    var image_width: CGFloat
    var image_height: CGFloat
    // Provide nodes as function of scene, camera
    var loadNodes: ((SCNView, SCNScene, SCNCamera) -> [SCNNode])
    // Provide nodes directly
    @State var nodes: [SCNNode] = []
    // Should rendering continue when no action is going on?
    var renderContinuously = false
    // Should default-camera-control be used?
    var defaultCameraControl = false
    // Called on each frame
    var onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)?
    // Called on gestures
    var onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onDoublePan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)?
    var onUIInit: ((SceneController) -> Void)?
    var onUIUpdate: ((SceneController) -> Void)?
    
    init(screen_width: CGFloat, screen_height: CGFloat, image_width: CGFloat, image_height: CGFloat, loadNodes: @escaping (SCNView, SCNScene, SCNCamera) -> [SCNNode], nodes: [SCNNode], renderContinuously: Bool = false, defaultCameraControl: Bool = false, onRender: ((SCNSceneRenderer, SCNView, [SCNNode]) -> Void)? = nil, onTap: ((UITapGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onPan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onDoublePan: ((UIPanGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onSwipe: ((UISwipeGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onPinch: ((UIPinchGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onRotate: ((UIRotationGestureRecognizer, SCNView, [SCNNode]) -> Void)? = nil, onUIInit: ((SceneController) -> Void)? = nil, onUIUpdate: ((SceneController) -> Void)? = nil) {
        print("Init SceneKitView")
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.image_width = image_width
        self.image_height = image_height
        self.loadNodes = loadNodes
        self.nodes = nodes
        self.renderContinuously = renderContinuously
        self.defaultCameraControl = defaultCameraControl
        self.onRender = onRender
        self.onTap = onTap
        self.onPan = onPan
        self.onDoublePan = onDoublePan
        self.onSwipe = onSwipe
        self.onPinch = onPinch
        self.onRotate = onRotate
        self.onUIInit = onUIInit
        self.onUIUpdate = onUIUpdate
    }
    
    func makeUIViewController(context: Context) -> SceneController {
        print("Creating SceneController")
        let sc = SceneController(
            screen_width: screen_width,
            screen_height: screen_height,
            image_width: image_width,
            image_height: image_height,
            loadNodes: loadNodes,
            nodes: nodes,
            renderContinuously: renderContinuously,
            defaultCameraControl: defaultCameraControl,
            onRender: onRender,
            onTap: onTap,
            onPan: onPan,
            onDoublePan: onDoublePan,
            onPinch: onPinch,
            onSwipe: onSwipe,
            onRotate: onRotate
        )
        if onUIInit != nil {
            onUIInit!(sc)
        }
        return sc
    }
    
    func updateUIViewController(_ uiViewController: SceneController, context: Context) {
        print("Updating SceneController")
        if onUIUpdate != nil {
            onUIUpdate!(uiViewController)
        }
    }

}


struct PreviewView: View {
    
    let width: CGFloat
    let height: CGFloat
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    
    @State var opacity = 1.0
    
    var body: some View {
        
        let ar = CGFloat(imageWidth) / CGFloat(imageHeight)
        let planeW: CGFloat = 2.0
        let planeH = planeW / ar
        let plane = SCNNode(geometry: SCNPlane(width: planeW, height: planeH))
        plane.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
//        plane.geometry!.firstMaterial!.diffuse.contents  = UIColor(red: 30.0 / 255.0, green: 150.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        plane.geometry!.firstMaterial!.diffuse.contents = UIImage(named: "uv_grid")
        
        let bx = SCNNode(geometry: SCNBox(width: 0.2, height: 0.3, length: 0.2, chamferRadius: 0.05))
        bx.geometry!.firstMaterial!.diffuse.contents  = UIColor(red: 125.0 / 255.0, green: 10.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        bx.position = SCNVector3(x: -0.5, y: 0.1, z: 0.0)
        
        return VStack {
            SceneKitView(
                screen_width: width,
                screen_height: height,
                image_width: imageWidth,
                image_height: imageHeight,
                loadNodes: { view, scene, camera in
                     return [plane, bx]
                 },
                nodes: [],
                 renderContinuously: true,
                 onRender: { renderer, view, nodes in
                     plane.opacity = opacity
                     bx.opacity = opacity
                 },
                 onTap: { gesture, view, nodes in
                     let hits = getGestureHits(view: view, gesture: gesture)
                     guard let node = hits.first else { return }
                     node.addAnimation(createPopAnimation(), forKey: "pop")
                 }
            )
//            .frame(width: CGFloat(width), height: CGFloat(height))
            .border(.red)
            
            Slider(value: $opacity, in: 0.0 ... 1.0)
            Text("Opacity: \(Int(opacity * 100)) %")
        }
    }
}

struct SceneKitView_Previews: PreviewProvider {
    static var previews: some View {
        let width: CGFloat = 900
        let height: CGFloat = 500
        let imageWidth: CGFloat = 200
        let imageHeight: CGFloat = 300
        
        PreviewView(width: width, height: height, imageWidth: imageWidth, imageHeight: imageHeight)
            .previewInterfaceOrientation(width > height ? .landscapeLeft : .portrait)
    }
}

// Animating SCNNode-opacity does not actually change the node's opacity.
// It's just that an additional effect on top of the nodes's opacity is applied
// as long as the animation is attached to the nodes.

// Hit detection only works on visible nodes
