//
//  HeadView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit


struct HeadView: View {

    // Image
    var image: UIImage
    // Parameters for detected faces
    var observations: [VNFaceObservation]
    
    var body: some View {
        
        SceneKitView(
            width: Int(image.size.width),
            height: Int(image.size.height),
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
            }
        )
    }
    
//    func opacity(_ opacity: Double) -> some View {
//        // @TODO: get nodes and update their opacity
//    }
    
    @State var rollOnMoveStart: Float?
    func rotate(view: SCNView, gesture: UIRotationGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else { return }
        let figure = getFigureForId(obsId: obsId, nodes: nodes)

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
        
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        let observation = observations.first(where: { $0.uuid == obsId })!
        
        let translation = gesture.translation(in: view)
        // pitch = rotation about x
        figure.eulerAngles.x = Float(4 * .pi * translation.y / image.size.width) + Float(observation.pitch!)
        // yaw = rotation about y
        figure.eulerAngles.y = Float(4 * .pi * translation.x / image.size.height) + Float(observation.yaw!)
    }
    
    @State var scaleOnStartMove: SCNVector3?
    func scale(view: SCNView, gesture: UIPinchGestureRecognizer, nodes: [SCNNode]) {
        guard let obsId = activeFace else {
            scaleSceneAndBackground(view: view, gesture: gesture, nodes: nodes)
            return
        }
        
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        
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
        
        switch gesture.state {
        case .began:
            cameraZOnStartMove = cameraNode.position.z
        case .changed:
            guard let z = cameraZOnStartMove else { return }
            let scaleFactor = pow( 1.0 / Float(gesture.scale), 0.25)
            cameraNode.position.z =  z * scaleFactor
        case .ended:
            cameraZOnStartMove = nil
        case .cancelled, .failed:
            cameraNode.position.z = cameraZOnStartMove!
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
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        
        switch gesture.state {
        case .began:
            positionOnStartMove = figure.position
        case .changed:
            guard let startPos = positionOnStartMove else { return }
            let translation = gesture.translation(in: view)  // in pixels
            figure.position.x = startPos.x + Float(translation.x / image.size.width) * 4.0
            figure.position.y = startPos.y - Float(translation.y / image.size.height) * 4.0
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
            cameraNode.position.x = startPos.x - Float(translation.x / image.size.width) * 4.0
            cameraNode.position.y = startPos.y + Float(translation.y / image.size.height) * 4.0
        case .ended:
            globalPositionOnStartMove = nil
        case .cancelled, .failed:
            cameraNode.position = globalPositionOnStartMove!
            globalPositionOnStartMove = nil
        default:
            return
        }
    }
    
    @State var activeFace: UUID?
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
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        figure.removeAnimation(forKey: "disappear")
        figure.addAnimation(createOpacityRevealAnimation(fromOpacity: 0.3, toOpacity: 1.0), forKey: "reveal")
        self.activeFace = obsId
    }

    func unfocusObservation(nodes: [SCNNode]) {
        guard let activeFace = self.activeFace else { return }
        let figure = getFigureForId(obsId: activeFace, nodes: nodes)
        figure.removeAnimation(forKey: "reveal")
        figure.addAnimation(createOpacityHideAnimation(fromOpacity: 1.0, toOpacity: 0.3), forKey: "disappear")
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
    
    func getFigureForId(obsId: UUID, nodes: [SCNNode]) -> SCNNode {
        let figure = nodes.first(where: {
            $0.value(forKey: "observationId") as? UUID == obsId     &&
            $0.value(forKey: "type") as? String == "figure"         &&
            $0.value(forKey: "root") != nil                         &&
            $0.value(forKey: "root") as! UUID == obsId
        })!
        return figure
    }
    
    func getNodes(scene: SCNScene) -> [SCNNode] {

        // loading model
        guard let loadedScene = SCNScene(named: "Loomis_Head.usdz") else { return [] }
        let figure = loadedScene.rootNode
        
        var nodes: [SCNNode] = []
        
        
//        ImageRelative               SceneKit               ImageRel    Scene
//
//                                       ar
//     1  ▲                               ▲                         1 │ ar
//        │                               │                           │
//        │                             1 │                           │
//        │                               │                           │
//        │                               │                           │
//        │                     -1        │        1                  │0
//        │                     ◄─────────┼────────►                  │
//        │                               │                           │
//        │                               │                           │
//        │                               │                           │
//        │                            -1 │                           │
//        │                               │                         0 │ -ar
//     0  └─────────────►                 ▼
//        0             1                ar
//
//
//                       Scene
//                       -1        0         1
//                       ─────────────────────
//                       0                   1
//                       ImageRel

        
        let ar = image.size.width / image.size.height
        let width = 2.0
        let height = width / ar
        let imagePlane = SCNNode(geometry: SCNPlane(width: width, height: height))
        imagePlane.position = SCNVector3(x: 0, y: 0, z: 0)
        imagePlane.geometry?.firstMaterial?.diffuse.contents = image
        imagePlane.name = "ImagePlane"
        imagePlane.setValue("ImagePlane", forKey: "type")
        
        // accounting for potential camera-orientation
//        if (image.imageOrientation == .right) {
//            let translation = SCNMatrix4MakeTranslation(-1, 0, 0)
//            let rotation = SCNMatrix4MakeRotation(-Float.pi / 2, 0, 0, 1)
//            let transform = SCNMatrix4Mult(translation, rotation)
//            imagePlane.geometry?.firstMaterial?.diffuse.contentsTransform = transform
//        }
        
        nodes.append(imagePlane)
        
        for observation in observations {
            
            // Unwrapping face-detection parameters
            let roll = Float(truncating: observation.roll!)
//            if (image.imageOrientation == .right) {
//                roll += Float.pi / 2.0
//            }
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
            
            let scaleFactor = (wImg * 0.5 + hImg * 0.5) / figure.boundingSphere.radius
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
}
        
    

struct HeadView_Previews: PreviewProvider {
    static var previews: some View {
        
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
        let size = img.size
        let ar = size.width / size.height
        let uiWidth = UIScreen.main.bounds.width
        let w = 0.8 * uiWidth
        let h = w / ar
        
        return ZStack {
            
            HeadView(
                image: img,
                observations: [observation1, observation2]
            ).border(.red)
            
        }.frame(width: w, height: h)
    }
}
