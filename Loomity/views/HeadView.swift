//
//  HeadView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit




enum TaskType {
    case addNode, removeNode, setOrthographicCam, setPerspectiveCam, takeScreenshot, recenterView
}

struct SKVTask {
    var type: TaskType
    var payload: UUID?
}


/**
 # Gesture sources
 Gestures may be recognised at to levels:
 - inside the scenekit scene (as recognised through `SceneKitView.onPinch` etc.)
 - in the parent HeadView (as recognised through `view.gesture`)
 
 # Gesture handling
 We want most gestures to be handled by scenekit
 with a few exceptions:
 - Pan while no model selected:
    - move the view, not the camera inside the scene (`.scaleEffect(fullViewScale)`)
 - Pinch while no model selected:
     - scale the view instead of moving the camera inside the scene (`.offset(fullViewOffset)`)
 */

struct HeadView: View {

    // Image
    var image: UIImage
    // Parameters for detected faces
    var observations: [VNFaceObservation]
    // task-state
    var taskQueue = Queue<SKVTask>()
    var usesOrthographicCam: Bool
    var onImageSaved: () -> Void
    var onImageSaveError: (Error) -> Void
    @Binding var opacity: Double
    @Binding var activeFace: UUID?
    
    let unfocussedOpacity = 0.5

    var body: some View {
        SceneKitView(
            screen_width: UIScreen.main.bounds.width,
            screen_height: UIScreen.main.bounds.height,
            image_width: image.size.width,
            image_height: image.size.height,
            loadNodes: { view, scene, camera in
                return self.getNodes(view: view, scene: scene)
            },
            onTap: { gesture, view, nodes in
                focusOnObservation(view: view, gesture: gesture, nodes: nodes)
            },
            onPan: { gesture, view, nodes in
                lookDirection(view: view, gesture: gesture, nodes: nodes)
            },
            onDoublePan: { gesture, view, nodes in
                moveInPlane(view: view, gesture: gesture, nodes: nodes)
            },
            onPinch: { gesture, view, nodes in
                scale(view: view, gesture: gesture, nodes: nodes)
            },
            onRotate: { gesture, view, nodes in
                rotate(view: view, gesture: gesture, nodes: nodes)
            },
            onUIInit: { skc in
                unfocusObservation(nodes: skc.nodes)
            },
            onUIUpdate: { skc in
                update(skc: skc, nodes: skc.nodes)
            }
        )
    }
    
    @State var lastOpacity: Double = 1.0
    func update(skc: SceneController, nodes: [SCNNode]) {
        
        for node in nodes {
            guard let type = node.value(forKey: "type") else { continue }
            if type as! String == "figure" {
                
                var maxOpacity = 1.0
                let obsId = node.value(forKey: "observationId") as! UUID
                if obsId != activeFace {
                    maxOpacity = self.unfocussedOpacity
                }
                
                var increasing = true
                if opacity - lastOpacity < 0.0 {
                    increasing = false
                }
                
                if increasing {
                    // when increasing, don't go above max-opacity
                    node.opacity = min(opacity, maxOpacity)
                } else {
                    // when decreasing, only decrease once below max-opacity
                    let targetOpacity = min(opacity, maxOpacity)
                    node.opacity = min(targetOpacity, node.opacity)
                }
                
                node.opacity = min(node.opacity, opacity)
            }
        }
        
        // only updating view-state after render-phase
        DispatchQueue.main.async {
            
            // 1. handling queued up tasks
            while let task = self.taskQueue.dequeue() {
                switch task.type {
                case .addNode:
                    let scene = skc.sceneView?.scene
                    let node = getNewFaceModel(scene: scene)
                    skc.newNode(node: node)
                    activeFace = node.value(forKey: "observationId") as? UUID
                case .removeNode:
                    skc.removeNodes(predicate: { node in
                        guard let uuid = node.value(forKey: "observationId") else { return false }
                        return (uuid as! UUID) == task.payload!
                    })
                    activeFace = nil
                case .setOrthographicCam:
                    skc.toggleOrthographicView(orthographic: true)
                case .setPerspectiveCam:
                    skc.toggleOrthographicView(orthographic: false)
                case .takeScreenshot:
                    guard let img = skc.screenshot() else { print("Error: couldn't get screenshot"); return }
                    let imageSaver = ImageSaver(onSuccess: self.onImageSaved, onError: self.onImageSaveError)
                    imageSaver.writeToPhotoAlbum(image: img)
                case .recenterView:
                    guard let view = skc.sceneView else { return }
                    // Not that simple. Need to account for screen rotation.
                    //view.transform = CGAffineTransformIdentity

                    let w_scr = UIScreen.main.bounds.width
                    let h_scr = UIScreen.main.bounds.height
                    let w_view = view.frame.width
                    let h_view = view.frame.height
                    let size_scene0 = CGSize(width: w_view, height: h_view)
                    let size_image0 = fitInto(inner: self.image.size, outer: size_scene0)
                    let size_screen = CGSize(width: w_scr, height: h_scr)
                    
                    let size_image1 = fitInto(inner: size_image0, outer: size_screen)
                    let size_scene1 = fitAround(outer: size_scene0, inner: size_image1)
                    
                    let centerX = size_screen.width / 2.0
                    let centerY = size_screen.height / 2.0
                    let scaleX = (size_scene1.width / size_scene0.width)
                    let scaleY = (size_scene1.height / size_scene0.height)

                    // IMPORTANT: don't translate a view with CGAffineTransform. Use center instead.
                    // Cite: Use this property to scale or rotate the view's frame rectangle within its superview's coordinate system. (To change the position of the view, modify the center property instead.) The default value of this property is CGAffineTransformIdentity.
                    // ALSO IMPORTANT: When the value of view.transform is anything other than the identity transform, the value in the frame property is undefined and should be ignored.
                    view.transform = CGAffineTransformScale(view.transform, scaleX, scaleY)
                    view.center = CGPoint(x: centerX, y: centerY)
                }
            }
            
            // 2. update opacity-state
            lastOpacity = opacity
            
        }
    }
    
    @State var rollOnMoveStart: Float?
    func rotate(view: SCNView, gesture: UIRotationGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else { return }
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }

        switch gesture.state {
        case .began:
            rollOnMoveStart = figure.eulerAngles.z
        case .changed:
            guard let roll = rollOnMoveStart else { return }
            figure.eulerAngles.z = roll - Float(gesture.rotation)
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
    
    @State var eulerAnglesOnStartMove: SCNVector3?
    func lookDirection(view: SCNView, gesture: UIPanGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else { return }
        
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
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
    
    @State var scaleOnStartMove: SCNVector3?
    func scale(view: SCNView, gesture: UIPinchGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else {
             scaleSceneAndBackground(view: view, gesture: gesture, nodes: nodes)
            return
        }
        
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
            figure.scale = scaleOnStartMove!
            scaleOnStartMove = nil
        default:
            return
        }
    }
    

    @State var lastScale: CGFloat?
    func scaleSceneAndBackground(view: SCNView, gesture: UIPinchGestureRecognizer, nodes: [SCNNode]) {
        switch gesture.state {
        case .began:
            lastScale = 1.0
        case .changed:
            guard let lastScale = lastScale else { return }
            let deltaScale = gesture.scale - lastScale
            let newScale = 1.0 + deltaScale
            self.lastScale = gesture.scale
            let newTransform = CGAffineTransformScale(view.transform, newScale, newScale)
            if (
                // scale is growing                && already deep in
                (newTransform.a > view.transform.a && newTransform.a > 3.0) ||
                (newTransform.a < view.transform.a && newTransform.a < 0.3333)
            ) {
                return
            }
            view.transform = newTransform
        case .ended:
            lastScale = nil
        case .failed, .cancelled:
            lastScale = nil
        default:
            return
        }
        return
    }
    
    @State var positionOnStartMove: SCNVector3?
    func moveInPlane(view: SCNView, gesture: UIPanGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else {
             panSceneAndBackground(view: view, gesture: gesture, nodes: nodes)
            return
        }
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        
        switch gesture.state {
        case .began:
            positionOnStartMove = figure.position
        case .changed:
            guard let startPos = positionOnStartMove else { return }
            let translation = gesture.translation(in: view)  // in pixels
            figure.position.x = startPos.x + Float(translation.x / UIScreen.main.bounds.width)  * 4.0
            figure.position.y = startPos.y - Float(translation.y / UIScreen.main.bounds.height) * 4.0
        case .ended:
            positionOnStartMove = nil
        case .cancelled, .failed:
            figure.position = positionOnStartMove!
            positionOnStartMove = nil
        default:
            return
        }
    }
    
    @State var centerOnStartMove: CGPoint?
    func panSceneAndBackground(view: SCNView, gesture: UIPanGestureRecognizer, nodes: [SCNNode]) {
        switch gesture.state {
        case .began:
            centerOnStartMove = view.center
        case .changed:
            guard let centerOnStart = centerOnStartMove else { return }
            let translation = gesture.translation(in: view)
            let centerNew = CGPoint(x: centerOnStart.x + translation.x, y: centerOnStart.y + translation.y)
            let centerScreen = CGPoint(x: UIScreen.main.bounds.width / 2.0, y: UIScreen.main.bounds.height / 2.0)
            if abs(centerNew.x) > UIScreen.main.bounds.width * 0.75 || abs(centerNew.y) > UIScreen.main.bounds.height * 0.75 {
                return
            }
            view.center = centerNew
        case .ended:
            centerOnStartMove = nil
        case .cancelled, .failed:
            guard let centerOnStart = centerOnStartMove else { return }
            view.center = centerOnStart
            centerOnStartMove = nil
        default:
            return
        }
        return
    }

    func focusOnObservation(view: SCNView, gesture: UIGestureRecognizer, nodes: [SCNNode]) {
        let node = getFirstHit(view: view, gesture: gesture)
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
    
    func focusObservation(obsId: UUID, nodes: [SCNNode]) {
        if self.activeFace == obsId { return }
        unfocusObservation(nodes: nodes)
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }
        animateAndApplyOpacity(node: figure, toOpacity: self.opacity)
        applyPopAnimation(node: figure)
        self.activeFace = obsId
    }

    func unfocusObservation(nodes: [SCNNode]) {
        guard let activeFace = self.activeFace else { return }
        guard let figure = getFigureForId(obsId: activeFace, nodes: nodes) else { return }
        animateAndApplyOpacity(node: figure, toOpacity: min(self.unfocussedOpacity, self.opacity))
        self.activeFace = nil
    }
    
    func getFirstHit(view: SCNView, gesture: UIGestureRecognizer) -> SCNNode? {
        let hits = getGestureHits(view: view, gesture: gesture)
        let node = hits.first(where: {
            ($0.value(forKey: "type") != nil)           &&
            ($0.value(forKey: "observationId") != nil)  &&
            ($0.opacity > 0.0)
        })
        return node
    }
    
    func getFigureForId(obsId: UUID, nodes: [SCNNode]) -> SCNNode? {
        let figure = nodes.first(where: {
            $0.value(forKey: "observationId") as? UUID == obsId     &&
            $0.value(forKey: "type") as? String == "figure"         &&
            $0.value(forKey: "root") != nil                         &&
            $0.value(forKey: "root") as! UUID == obsId
        })
        return figure
    }
    
    func getNodes(view: SCNView, scene: SCNScene) -> [SCNNode] {

        let modelName = "loomisNew.usdz"
        guard let loadedScene = SCNScene(named: modelName) else { return [] }
        let figure = loadedScene.rootNode
        
        var nodes: [SCNNode] = []
        
        let ar = image.size.width / image.size.height
        let width = 2.0
        let height = width / ar
        let imagePlane = SCNNode(geometry: SCNPlane(width: width, height: height))
        imagePlane.position = SCNVector3(x: 0, y: 0, z: 0)
        imagePlane.geometry?.firstMaterial?.diffuse.contents = image
        imagePlane.name = "ImagePlane"
        imagePlane.setValue("ImagePlane", forKey: "type")
        
        nodes.append(imagePlane)
        
        for observation in observations {
            
            // Unwrapping face-detection parameters
            let roll  = Float(truncating: observation.roll!)
            let pitch = Float(truncating: observation.pitch!)
            let yaw   = Float(truncating: observation.yaw!)
            
            let cWorld = obsBboxCenter2Scene(boundingBox: observation.boundingBox, imageWidth: image.size.width, imageHeight: image.size.height)
            
            let f = figure.clone()
            
            // we only use width for scale factor because face-detection doesn't include forehead,
            // rendering the height-value useless for scaling.
            let headHeightPerWidth: Float = 1.3
            let wImg = Float(observation.boundingBox.maxX - observation.boundingBox.minX)
            let scaleFactor = 3.0 * headHeightPerWidth * (wImg) / figure.boundingSphere.radius
            f.scale = SCNVector3( x: scaleFactor, y: scaleFactor, z: scaleFactor )
            f.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
            f.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            f.opacity = self.unfocussedOpacity
            f.setValue(observation.uuid, forKey: "root")
            setValueRecursively(node: f, val: "figure", key: "type")
            setValueRecursively(node: f, val: observation.uuid, key: "observationId")
            applyPopAnimation(node: f)
            
            let fOptimised = gradientDescent(sceneView: view, head: f, observation: observation, image: self.image)

            // @Todo: where is this weird behaviour coming from?
            if !usesOrthographicCam {
                let weirdCorrectionFactor: Float = 0.3 * Float(observation.boundingBox.width)
                fOptimised.position.y -= weirdCorrectionFactor
            }

            nodes.append(fOptimised)
        }
        
        return nodes
    }

    func __getAllPoints(observation: VNFaceObservation) -> [CGPoint] {
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

    func setModelColor(model: SCNNode, color: UIColor) {
        model.geometry?.firstMaterial?.diffuse.contents = color
        for child in model.childNodes {
            setModelColor(model: child, color: color)
        }
    }
    
    func getNewFaceModel(scene: SCNScene?) -> SCNNode {
        let loadedScene = SCNScene(named: "loomisNew.usdz")!
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
}



struct PrevV: View {
    
    let observation1 = VNFaceObservation(
        requestRevision: 0,
        boundingBox: CGRect(x: 0.545, y: 0.276, width: 0.439, height: 0.436),
        roll: 0.138,
        yaw: -0.482,
        pitch: 0.112
    )
    
    let observation2 = VNFaceObservation(
        requestRevision: 0,
        boundingBox: CGRect(x: 0.218, y: 0.248, width: 0.382, height: 0.379),
        roll: -0.216,
        yaw: 0.121,
        pitch: 0.151
    )
    
    let img = UIImage(named: "TestImage2")!
    
    let queue = Queue<SKVTask>()
    
    @State var useOrtho = false
    @State var activeFace: UUID? = nil
    @State var opacity = 1.0
    
    var body: some View {
        HeadView(
            image: img,
            observations: [observation1, observation2],
            taskQueue: queue,
            usesOrthographicCam: useOrtho,
            onImageSaved: {},
            onImageSaveError: { error in return },
            opacity: $opacity,
            activeFace: $activeFace
        ).onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activeFace = observation2.uuid
            }
        }
    }
}

struct HeadView_Previews: PreviewProvider {
    static var previews: some View {
        PrevV()
    }
}
