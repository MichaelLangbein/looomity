//
//  ModelView.swift
//  newscene
//
//  Created by Michael Langbein on 28.01.23.
//

import SwiftUI
import SceneKit
import Vision



class ModelController: UIViewController, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {
    
    private var w_scr: CGFloat
    private var h_scr: CGFloat
    private var image: UIImage
    private var projectedScene: SCNView!
    private var mainScene: SCNView!
    private var screen: SCNNode!
    private var observations: [VNFaceObservation]
    
    // model state
    private var activeFace: UUID?
    private var nodes: [SCNNode] = []
    
    // opacity state
    private let unfocussedOpacity = 0.5
    private var opacity = 1.0

    init(w_scr: CGFloat, h_scr: CGFloat, image: UIImage, observations: [VNFaceObservation]) {
        self.w_scr = w_scr
        self.h_scr = h_scr
        self.image = image
        self.observations = observations
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let w_img = self.image.size.width
        let h_img = self.image.size.height

        self.projectedScene = initProjectedScene(
            frame: CGRect(x: 0, y: 0, width: w_img, height: h_img),
            observations: self.observations
        )
        self.projectedScene.layer.borderWidth = 1
        self.projectedScene.layer.borderColor = .init(red: 256, green: 0, blue: 0, alpha: 1)
        self.projectedScene.layer.contentsScale = 1.0
        
        self.mainScene = initReceivingScene(
            frame: CGRect(x: 0, y: 0, width: self.w_scr, height: self.h_scr),
            image: self.image
        )
        self.mainScene.layer.borderWidth = 1
        self.mainScene.layer.borderColor = .init(red: 0, green: 256, blue: 0, alpha: 1)
        
        self.screen = self.mainScene.scene?.rootNode.childNode(withName: "Screen", recursively: true)!
        self.screen.geometry?.firstMaterial?.diffuse.contents = self.projectedScene.layer
        
        initGestures()
        
        self.view = UIView()
        self.view.addSubview(mainScene)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime: TimeInterval) {}
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Can those two gestures be handles at the same time?
        return true
    }
    
    func initProjectedScene(frame: CGRect, observations: [VNFaceObservation]) -> SCNView {
        let sceneView = SCNView(frame: frame)
        sceneView.delegate = self
        sceneView.backgroundColor = UIColor(.gray.opacity(0.0))
        sceneView.autoenablesDefaultLighting = true
//        sceneView.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        let image_size_scene = CGSize(
            width: 2.0,
            height: 2.0 * image.size.height / image.size.width
        )
        let image_size_clip = fitImageIntoClip(
            width_screen: frame.width, height_screen: frame.height,
            width_img: image.size.width, height_img: image.size.height
        )
        let zCam = distanceSoCamSeesAllOfImage(
            camera: camera,
            imageSizeClip: image_size_clip,
            imageSizeScene: image_size_scene
        )
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCam)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        
        let model = SCNScene(named: "loomis.usdz")!
        let figure = model.rootNode
        for observation in observations {
            
            // Unwrapping face-detection parameters
            let roll  = Float(truncating: observation.roll!)
            let pitch = Float(truncating: observation.pitch!)
            let yaw   = Float(truncating: observation.yaw!)
            
            let cWorld = obsBboxCenter2Scene(boundingBox: observation.boundingBox, imageWidth: frame.width, imageHeight: frame.height)
            
            let f = figure.clone()
            
            // we only use width for scale factor because face-detection doesn't include forehead,
            // rendering the height-value useless for scaling.
            let headHeightPerWidth: Float = 1.3
            let wImg = Float(observation.boundingBox.maxX - observation.boundingBox.minX)
            let scaleFactor = 3.0 * headHeightPerWidth * (wImg) / figure.boundingSphere.radius
            f.scale = SCNVector3(x: scaleFactor, y: scaleFactor, z: scaleFactor)
            f.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
            f.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            f.opacity = self.unfocussedOpacity
            f.setValue(observation.uuid, forKey: "root")
            setValueRecursively(node: f, val: "figure", key: "type")
            setValueRecursively(node: f, val: observation.uuid, key: "observationId")
            applyPopAnimation(node: f)
            
            let fOptimised = gradientDescent(sceneView: sceneView, head: f, observation: observation, image: self.image)
            
            // @Todo: where is this weird behaviour coming from?
            //                let weirdCorrectionFactor: Float = 0.3 * Float(observation.boundingBox.width)
            //                fOptimised.position.y -= weirdCorrectionFactor
            
            scene.rootNode.addChildNode(fOptimised)
            self.nodes.append(fOptimised)
            
            
            for point in __getAllPoints(observation: observation) {
                let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
                box.firstMaterial?.diffuse.contents = Color(.yellow)
                let node = SCNNode(geometry: box)
                let imagePoint = landmark2image(point, observation.boundingBox)
                let scenePoint = image2scene(imagePoint, 2.0, 2.0 * image.size.height / image.size.width)
                node.position = scenePoint
                scene.rootNode.addChildNode(node)
            }
        }
        
        return sceneView
    }
    
    func initReceivingScene(frame: CGRect, image: UIImage) -> SCNView {
        let sceneView = SCNView(frame: frame)
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        camera.zNear = 0.0001
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        let image_size_scene = CGSize(
            width: 2.0,
            height: 2.0 * image.size.height / image.size.width
        )
        let image_size_clip = fitImageIntoClip(
            width_screen: frame.width, height_screen: frame.height,
            width_img: image.size.width, height_img: image.size.height
        )
        let zCam = distanceSoCamSeesAllOfImage(
            camera: camera,
            imageSizeClip: image_size_clip,
            imageSizeScene: image_size_scene
        )
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCam)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        
        let imagePlane = SCNPlane(width: image_size_scene.width, height: image_size_scene.height)
        imagePlane.firstMaterial?.diffuse.contents = image
        let imageNode = SCNNode(geometry: imagePlane)
        imageNode.name = "Image"
        imageNode.position = SCNVector3(0, 0, -0.01)
        scene.rootNode.addChildNode(imageNode)
        
        let projectionPlane = SCNPlane(width: image_size_scene.width, height: image_size_scene.height)
        let projectionPlaneNode = SCNNode(geometry: projectionPlane)
        projectionPlaneNode.name = "Screen"
        scene.rootNode.addChildNode(projectionPlaneNode)
        
        return sceneView
    }
    
    func initGestures() {
        let tapRecognizer    = UITapGestureRecognizer(      target: self, action: #selector(handleTap(tapGesture:))       )
        let pinchRecognizer  = UIPinchGestureRecognizer(    target: self, action: #selector(handlePinch(pinchGesture:))   )
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
        rotateRecognizer.delegate = self
        self.mainScene.addGestureRecognizer(panRecognizer)
        self.mainScene.addGestureRecognizer(doublePanRecognizer)
        self.mainScene.addGestureRecognizer(tapRecognizer)
        self.mainScene.addGestureRecognizer(pinchRecognizer)
        self.mainScene.addGestureRecognizer(rotateRecognizer)
    }
    
    private var eulerAnglesOnStartMove: SCNVector3?
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        guard let obsId = activeFace else { return }
        
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        
        let translation = panGesture.translation(in: view)
        
        switch panGesture.state {
        case .began:
            eulerAnglesOnStartMove = figure.eulerAngles
        case .changed:
            guard let initial = eulerAnglesOnStartMove else { return }
            // pitch = rotation about x
            figure.eulerAngles.x = Float(4 * .pi * translation.y / image.size.width) + Float(initial.x)
            // yaw = rotation about y
            figure.eulerAngles.y = Float(4 * .pi * translation.x / image.size.height) + Float(initial.y)
        case .ended:
            eulerAnglesOnStartMove = nil
        case .cancelled, .failed:
            guard let initial = eulerAnglesOnStartMove else { return }
            figure.eulerAngles = initial
            eulerAnglesOnStartMove = nil
        default:
            return
        }
    }
    
    private var rollOnMoveStart: Float?
    @objc func handleRotate(rotateGesture: UIRotationGestureRecognizer) {
        guard let obsId = activeFace else { return }
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }

        switch rotateGesture.state {
        case .began:
            rollOnMoveStart = figure.eulerAngles.z
        case .changed:
            guard let roll = rollOnMoveStart else { return }
            figure.eulerAngles.z = roll - Float(rotateGesture.rotation)
        case .ended:
            rollOnMoveStart = nil
        case .cancelled, .failed:
            guard let roll = rollOnMoveStart else { return }
            figure.eulerAngles.z = roll
            rollOnMoveStart = nil
        default:
            return
        }
    }
    
    @objc func handleDoublePan(panGesture: UIPanGestureRecognizer) {
        if let obsId = activeFace {
            moveInPlane(gesture: panGesture, obsId: obsId)
        } else {
            moveGloballyInPlane(gesture: panGesture)
        }
    }
    
    private var positionOnStartMove: SCNVector3?
    func moveInPlane(gesture: UIPanGestureRecognizer, obsId: UUID) {
        guard
            let figure = getFigureForId(obsId: obsId, nodes: nodes),
            let scene = self.projectedScene.scene,
            let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true)
        else { return }
        
        switch gesture.state {
        case .began:
            positionOnStartMove = figure.position
        case .changed:
            guard let startPos = positionOnStartMove else { return }
            let translation = gesture.translation(in: view)  // in pixels
                              //  start    + relative translation             * a bit faster * slower when zoomed in
            figure.position.x = startPos.x + Float(translation.x / image.size.width)  * 4.0 * cameraNode.position.z
            figure.position.y = startPos.y - Float(translation.y / image.size.height) * 4.0 * cameraNode.position.z
        case .ended:
            positionOnStartMove = nil
        case .cancelled, .failed:
            figure.position = positionOnStartMove!
            positionOnStartMove = nil
        default:
            return
        }
    }
    
    private var globalPositionOnStartMove: SCNVector3?
    func moveGloballyInPlane(gesture: UIPanGestureRecognizer) {
        guard let cameraNode = self.mainScene.scene?.rootNode.childNode(withName: "Camera", recursively: true) else { return }
        
        switch gesture.state {
        case .began:
            globalPositionOnStartMove = cameraNode.position
        case .changed:
            guard let startPos = globalPositionOnStartMove else { return }
            let translation = gesture.translation(in: view)
                                        //  start         + relative translation
            cameraNode.position.x = startPos.x - Float(translation.x / image.size.width)  * 2.0 * cameraNode.position.z
            cameraNode.position.y = startPos.y + Float(translation.y / image.size.height) * 2.0 * cameraNode.position.z
        case .ended:
            globalPositionOnStartMove = nil
        case .cancelled, .failed:
            guard let startPos = globalPositionOnStartMove else { return }
            cameraNode.position = startPos
            globalPositionOnStartMove = nil
        default:
            return
        }
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        let node = getFirstHit(view: self.projectedScene, gesture: tapGesture)
        if node == nil {
            unfocusObservation(nodes: nodes)
            return
        }
        let type = node!.value(forKey: "type") as! String
        let obsId = node!.value(forKey: "observationId") as! UUID
        if type == "figure" {
            focusObservation(obsId: obsId, nodes: nodes)
        } else {
            unfocusObservation(nodes: nodes)
        }
    }
    
    @objc func handlePinch(pinchGesture: UIPinchGestureRecognizer) {
        if let obsId = activeFace {
            scaleModel(gesture: pinchGesture, obsId: obsId)
        } else {
            scaleGlobally(gesture: pinchGesture)
        }
    }
    
    private var scaleOnStartMove: SCNVector3?
    func scaleModel(gesture: UIPinchGestureRecognizer, obsId: UUID) {
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        
        switch gesture.state {
        case .began:
            scaleOnStartMove = figure.scale
        case .changed:
            guard let initial = scaleOnStartMove else { return }
            let s = Float(gesture.scale)
            figure.scale = SCNVector3(x: initial.x * s, y: initial.y * s, z: initial.z * s)
        case .ended:
            scaleOnStartMove = nil
        case .cancelled, .failed:
            guard let initial = scaleOnStartMove else { return }
            figure.scale = initial
            scaleOnStartMove = nil
        default:
            return
        }
    }
    
    private var zPosCameraOnStartMove: Float?
    func scaleGlobally(gesture: UIPinchGestureRecognizer) {
        guard let cameraNode = self.mainScene.scene?.rootNode.childNode(withName: "Camera", recursively: true) else { return }
        
        switch gesture.state {
        case .began:
            zPosCameraOnStartMove = cameraNode.position.z
        case .changed:
            guard let initialZ = zPosCameraOnStartMove else { return }
            var newZ = initialZ / Float(gesture.scale)
            newZ = max(newZ, 0.01)  // mustn't go too close
            newZ = min(newZ, 10)    // mustn't go too far away
            cameraNode.position.z = newZ
        case .ended:
            zPosCameraOnStartMove = nil
        case .failed, .cancelled:
            guard let initialZ = zPosCameraOnStartMove else { return }
            cameraNode.position.z = initialZ
            zPosCameraOnStartMove = nil
        default:
            return
        }
    }
    
    private func __getAllPoints(observation: VNFaceObservation) -> [CGPoint] {
        var points: [CGPoint] = []
        for point in observation.landmarks!.outerLips!.normalizedPoints {
            points.append(point);
        }
        for point in observation.landmarks!.nose!.normalizedPoints {
            points.append(point);
        }
        for point in observation.landmarks!.leftEye!.normalizedPoints {
            points.append(point);
        }
        for point in observation.landmarks!.rightEye!.normalizedPoints {
            points.append(point);
        }
        for point in observation.landmarks!.leftEyebrow!.normalizedPoints {
            points.append(point);
        }
        for point in observation.landmarks!.rightEyebrow!.normalizedPoints {
            points.append(point);
        }
//        for point in observation.landmarks!.faceContour!.normalizedPoints {
//            points.append(point);
//        }
        for point in observation.landmarks!.medianLine!.normalizedPoints {
            points.append(point)
        }
        return points;
    }
    
    private func focusObservation(obsId: UUID, nodes: [SCNNode]) {
        if self.activeFace == obsId { return }
        unfocusObservation(nodes: nodes)
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        animateAndApplyOpacity(node: figure, toOpacity: self.opacity)
        applyPopAnimation(node: figure)
        self.activeFace = obsId
    }

    private func unfocusObservation(nodes: [SCNNode]) {
        guard let activeFace = self.activeFace else { return }
        guard let figure = getFigureForId(obsId: activeFace, nodes: nodes) else { return }
        animateAndApplyOpacity(node: figure, toOpacity: min(self.unfocussedOpacity, self.opacity))
        self.activeFace = nil
    }
    
    private func getFirstHit(view: SCNView, gesture: UIGestureRecognizer) -> SCNNode? {
        let location = gesture.location(in: self.mainScene)
        return nodes[0]
    }
    
    private func getNewFaceModel(scene: SCNScene?) -> SCNNode {
        let loadedScene = SCNScene(named: "loomis.usdz")!
        let figure = loadedScene.rootNode
        
        var newPosition = SCNVector3(x: 0, y: 0, z: 0)
        var scale: Float = 1.0
        var lookAt = SCNVector3(x: 0, y: 0, z: 1.0)
        if let cameraNode = scene?.rootNode.childNode(withName: "Camera", recursively: true) {
            newPosition.x = cameraNode.position.x
            newPosition.y = cameraNode.position.y
            scale = cameraNode.position.z / 2.0
            if scale < 0 {
                scale = -scale
            }
            lookAt = cameraNode.position
        }
        
        let f = figure.clone()
        f.position = newPosition
        f.look(at: lookAt) // SCNVector3(x: newPosition.x, y: newPosition.y, z: 10000))
        let scaleFactor = scale / f.boundingSphere.radius
        
        f.scale = SCNVector3(x: scaleFactor, y: scaleFactor, z: scaleFactor)
        let newUUID = UUID()
        f.setValue(newUUID, forKey: "root")
        setValueRecursively(node: f, val: "figure", key: "type")
        setValueRecursively(node: f, val: newUUID, key: "observationId")
        f.opacity = min(self.opacity, self.unfocussedOpacity)
        return f
    }
    
    private func getFigureForId(obsId: UUID, nodes: [SCNNode]) -> SCNNode? {
        let figure = nodes.first(where: {
            $0.value(forKey: "observationId") as? UUID == obsId     &&
            $0.value(forKey: "type") as? String == "figure"         &&
            $0.value(forKey: "root") != nil                         &&
            $0.value(forKey: "root") as! UUID == obsId
        })
        return figure
    }
    
}


struct ModelView: UIViewControllerRepresentable {
    let image: UIImage
    let observations: [VNFaceObservation]
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ModelController(w_scr: UIScreen.main.bounds.width * 0.9, h_scr: UIScreen.main.bounds.height * 0.9, image: image, observations: observations)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct ModelViewPreview: View {
    private let image = UIImage(named: "TestImage2")!
    @State var observations: [VNFaceObservation]?
    
    var body: some View {
        VStack {
            if let obs = observations {
                ModelView(image: self.image, observations: obs)
            } else {
                Text("Detecting faces ...")
            }
        }.onAppear {
            detectFacesWithLandmarks(uiImage: self.image) { observations in
                self.observations = observations
            }
        }
    }
}

struct ModelView_Previews: PreviewProvider {
    static var previews: some View {
        ModelViewPreview()
    }
}
