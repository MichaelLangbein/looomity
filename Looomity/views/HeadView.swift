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
    case addNode, removeNode, setOrthographicCam, setPerspectiveCam, takeScreenshot
}

struct SKVTask {
    var type: TaskType
    var payload: UUID?
}


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
    var opacity: Double = 1.0
    @Binding var activeFace: UUID?

    var body: some View {
            SceneKitView(
                width: Int(UIScreen.main.bounds.width * 1.2),     // Int(image.size.width),
                height: Int(UIScreen.main.bounds.height),   // Int(image.size.height),
                loadNodes: { view, scene, camera in
                    return self.getNodes(scene: scene)
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
                    print("UIInit")
                },
                onUIUpdate: { skc in
                    update(skc: skc, nodes: skc.nodes)
                    print("UIUpdate")
                }
            )
    }
    
    @State var lastOpacity: Double = 1.0
    func update(skc: SceneController, nodes: [SCNNode]) {
        
        for node in nodes {
            let type = node.value(forKey: "type") as! String
            if type  == "figure" {
                
                var maxOpacity = 1.0
                let obsId = node.value(forKey: "observationId") as! UUID
                if obsId != activeFace {
                    maxOpacity = 0.3
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
                    let node = getFaceModel()
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
    
    func lookDirection(view: SCNView, gesture: UIPanGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else { return }
        
        guard let figure = getFigureForId(obsId: obsId, nodes: nodes) else { return }

        // Manually added models don't have an observation - so we provide a fallback
        let observation = observations.first(where: { $0.uuid == obsId }) ?? VNFaceObservation(requestRevision: 0, boundingBox: CGRect(), roll: 0, yaw: 0, pitch: 0)
        
        let translation = gesture.translation(in: view)
        // pitch = rotation about x
        figure.eulerAngles.x = Float(4 * .pi * translation.y / image.size.width) + Float(truncating: observation.pitch!)
        // yaw = rotation about y
        figure.eulerAngles.y = Float(4 * .pi * translation.x / image.size.height) + Float(truncating: observation.yaw!)
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
    
    @State var cameraZOnStartMove: Float?
    func scaleSceneAndBackground(view: SCNView, gesture: UIPinchGestureRecognizer, nodes: [SCNNode]) {
        guard let rootNode = view.scene?.rootNode else { return }
        guard let cameraNode = rootNode.childNode(withName: "Camera", recursively: true) else { return }
        guard let camera = cameraNode.camera else { return }
        let ortho = camera.usesOrthographicProjection
        
        switch gesture.state {
        case .began:
            cameraZOnStartMove = ortho ? Float(camera.orthographicScale) : cameraNode.position.z
        case .changed:
            guard let z = cameraZOnStartMove else { return }
            let scaleFactor = pow( 1.0 / Float(gesture.scale), 1.0)
            cameraNode.position.z =  z * scaleFactor
            cameraNode.camera?.orthographicScale = Double(z * scaleFactor)
        case .ended:
            cameraZOnStartMove = nil
        case .cancelled, .failed:
            cameraNode.position.z = cameraZOnStartMove!
            camera.orthographicScale = Double(cameraZOnStartMove!)
            cameraZOnStartMove = nil
        default:
            return
        }
        
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
            figure.position.x = startPos.x + Float(translation.x / image.size.width) * 8.0
            figure.position.y = startPos.y - Float(translation.y / image.size.height) * 8.0
        case .ended:
            positionOnStartMove = nil
        case .cancelled, .failed:
            figure.position = positionOnStartMove!
            positionOnStartMove = nil
        default:
            return
        }
    }
    
    @State var globalPositionOnStartMove: SCNVector3?
    func panSceneAndBackground(view: SCNView, gesture: UIPanGestureRecognizer, nodes: [SCNNode]) {
        guard let scene = view.scene else { return }
        guard let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true) else { return }
        
        switch gesture.state {
        case .began:
            globalPositionOnStartMove = cameraNode.position
        case .changed:
            guard let startPos = globalPositionOnStartMove else { return }
            let translation = gesture.translation(in: view)  // in pixels
            cameraNode.position.x = startPos.x - Float(translation.x / image.size.width) * 8.0
            cameraNode.position.y = startPos.y + Float(translation.y / image.size.height) * 8.0
        case .ended:
            globalPositionOnStartMove = nil
        case .cancelled, .failed:
            cameraNode.position = globalPositionOnStartMove!
            globalPositionOnStartMove = nil
        default:
            return
        }
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
        animateAndApplyOpacity(node: figure, toOpacity: 1.0)
        self.activeFace = obsId
    }

    func unfocusObservation(nodes: [SCNNode]) {
        guard let activeFace = self.activeFace else { return }
        guard let figure = getFigureForId(obsId: activeFace, nodes: nodes) else { return }
        animateAndApplyOpacity(node: figure, toOpacity: 0.3)
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
    
    func getNodes(scene: SCNScene) -> [SCNNode] {

        // loading model
        guard let loadedScene = SCNScene(named: "Loomis_Head.usdz") else { return [] }
        let figure = loadedScene.rootNode
        
        var nodes: [SCNNode] = []
        
        
//        ImageRelative               SceneKit               ImageRel    Scene
//
//     1  ▲                               ▲ ar                      1 ▲ ar
//        │                               │                           │
//        │                             1 │                           │ 1
//        │                               │                           │
//        │                               │                           │
//        │                     -1        │        1                  │
//        │                     ◄─────────┼────────►                  │ 0
//        │                               │                           │
//        │                               │                           │
//        │                               │                           │
//        │                            -1 │                           │ -1
//        │                               │                           │
//     0  └─────────────►                 ▼ -ar                     0 ▼ -ar
//        0             1
//
//                       Scene
//                       -1        0         1
//                       ◄───────────────────►
//                       0                   1
//                       ImageRel

        // Normally here we'd have to account for `image.imageOrientation != .up`
        // But this is already fixed manually after taking the image in the image-picker
        
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
            let roll = Float(truncating: observation.roll!)
            let pitch = Float(truncating: observation.pitch!)
            let yaw = Float(truncating: observation.yaw!)
            
            let leftImg = Float(observation.boundingBox.minX)
            let rightImg = Float(observation.boundingBox.maxX)
            let topImg = Float(observation.boundingBox.maxY)
            let bottomImg = Float(observation.boundingBox.minY)
            
            let wImg = rightImg - leftImg
            let hImg = topImg - bottomImg
            let xImg = leftImg   + wImg / 2.0
            let yImg = bottomImg + hImg / 2.0
            let xScene = 2.0 * xImg - 1.0
            let yScene = (2.0 * yImg - 1.0) * Float(ar)
            let cWorld = SCNVector3(x: xScene, y: yScene, z: 0)
            
            let f = figure.clone()
            
            // we only use width for scale factor because face-detection doesn't include forehead,
            // rendering the height-value useless for scaling.
            let scaleFactor = 1.3 * (wImg) / figure.boundingSphere.radius
            f.scale = SCNVector3( x: scaleFactor, y: scaleFactor, z: scaleFactor )
            f.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
            f.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            f.opacity = 0.3
            f.setValue(observation.uuid, forKey: "root")
            setValueRecursively(node: f, val: "figure", key: "type")
            setValueRecursively(node: f, val: observation.uuid, key: "observationId")
            
            nodes.append(f)
        }
        
        return nodes
    }
    
    func getFaceModel() -> SCNNode {
        let loadedScene = SCNScene(named: "Loomis_Head.usdz")!
        let figure = loadedScene.rootNode
        let f = figure.clone()
        f.position = SCNVector3(x: 0, y: 0, z: 0)
        f.look(at: SCNVector3(x: 0, y: 0, z: 1))
        let scaleFactor = 1.0 / f.boundingSphere.radius
        f.scale = SCNVector3(x: scaleFactor, y: scaleFactor, z: scaleFactor)
        let newUUID = UUID()
        f.setValue(newUUID, forKey: "root")
        setValueRecursively(node: f, val: "figure", key: "type")
        setValueRecursively(node: f, val: newUUID, key: "observationId")
        f.opacity = min(opacity, 0.3)
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
    
    var body: some View {
        HeadView(
            image: img,
            observations: [observation1, observation2],
            taskQueue: queue,
            usesOrthographicCam: useOrtho,
            onImageSaved: {},
            onImageSaveError: { error in return },
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
