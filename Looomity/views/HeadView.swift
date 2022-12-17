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

    // Parameters for detected faces
    var observations: [VNFaceObservation]
    // Aspect-ratio of underlying photo
    var imageSize: CGSize
    var onImagePinch: ((UIPinchGestureRecognizer) -> Void)?
    
    var body: some View {
        
        SceneKitView(
            width: Int(imageSize.width),
            height: Int(imageSize.height),
            loadNodes: { view, scene, camera in
                return self.getNodes(scene: scene)
            },
            onTap: { gesture, view, nodes in
                togglePlaneVsModel(view: view, gesture: gesture, nodes: nodes)
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
    
    @State var rollOnMoveStart: Float?
    func rotate(view: SCNView, gesture: UIRotationGestureRecognizer, nodes: [SCNNode]) {
        guard let node = getFirstHit(view: view, gesture: gesture) else { return }
        let type = node.value(forKey: "type") as! String
        if type != "figure" { return }
        let obsId = node.value(forKey: "observationId") as! UUID
        let figure = getFigureForId(obsId: obsId, nodes: nodes)

        switch gesture.state {
        case .began:
            rollOnMoveStart = figure.eulerAngles.z
        case .changed:
            figure.eulerAngles.z = rollOnMoveStart! - Float(gesture.rotation)
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
        guard let node = getFirstHit(view: view, gesture: gesture) else { return }
        let type = node.value(forKey: "type") as! String
        if type != "figure" { return }
        let obsId = node.value(forKey: "observationId") as! UUID
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        let observation = observations.first(where: { $0.uuid == obsId })!
        
        let translation = gesture.translation(in: view)
        // pitch = rotation about x
        figure.eulerAngles.x = Float(4 * .pi * translation.y / imageSize.width) + Float(observation.pitch!)
        // yaw = rotation about y
        figure.eulerAngles.y = Float(4 * .pi * translation.x / imageSize.height) + Float(observation.yaw!)
    }
    
    
    @State var scaleOnStartMove: SCNVector3?
    func scale(view: SCNView, gesture: UIPinchGestureRecognizer, nodes: [SCNNode]) {
        guard let node = getFirstHit(view: view, gesture: gesture) else {
            scaleSceneAndBackground(view: view, gesture: gesture, nodes: nodes)
            return
        }
        let type = node.value(forKey: "type") as! String
        if type != "figure" { return }
        let obsId = node.value(forKey: "observationId") as! UUID
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
        guard let camera = cameraNode.camera else { return }
        
        if onImagePinch != nil {
            onImagePinch!(gesture)
        }
        
        switch gesture.state {
        case .began:
            cameraZOnStartMove = cameraNode.position.z
        case .changed:
            cameraNode.position.z = Float(gesture.scale) * cameraZOnStartMove!
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
        guard let node = getFirstHit(view: view, gesture: gesture) else { return }
        let type = node.value(forKey: "type") as! String
        if type != "figure" { return }
        let obsId = node.value(forKey: "observationId") as! UUID
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        
        switch gesture.state {
        case .began:
            positionOnStartMove = figure.position
        case .changed:
            guard let startPos = positionOnStartMove else { return }
            let translation = gesture.translation(in: view)
            let dist = (startPos.x * startPos.x  + startPos.y * startPos.y  + startPos.z * startPos.z).squareRoot()
            figure.position.x = 0.001 * (startPos.x + Float(translation.x)) * dist
            figure.position.y = 0.001 * (startPos.y + Float(translation.y)) * dist
        case .ended:
            positionOnStartMove = nil
        case .cancelled, .failed:
            figure.position = positionOnStartMove!
            positionOnStartMove = nil
        default:
            return
        }
    }
    
    @State var activeFace: UUID?
    func togglePlaneVsModel(view: SCNView, gesture: UIGestureRecognizer, nodes: [SCNNode]) {
        let node = getFirstHit(view: view, gesture: gesture)
        if node == nil {
            unfocusObservation(nodes: nodes)
            return
        }
        let type = node!.value(forKey: "type") as! String
        let obsId = node!.value(forKey: "observationId") as! UUID
        if type == "plane" {
            focusObservation(obsId: obsId, nodes: nodes)
        } else {
            unfocusObservation(nodes: nodes)
        }
    }
    
    func focusObservation(obsId: UUID, nodes: [SCNNode]) {
        if self.activeFace == obsId { return }
        unfocusObservation(nodes: nodes)
        let figure = getFigureForId(obsId: obsId, nodes: nodes)
        let plane = getPlaneForId(obsId: obsId, nodes: nodes)
        plane.removeAnimation(forKey: "reveal")
        plane.addAnimation(createOpacityHideAnimation(fromOpacity: 0.3, toOpacity: 0.0), forKey: "disappear")
        figure.removeAnimation(forKey: "disappear")
        figure.addAnimation(createOpacityRevealAnimation(fromOpacity: 0.0, toOpacity: 1.0), forKey: "reveal")
        self.activeFace = obsId
    }
    
    func unfocusObservation(nodes: [SCNNode]) {
        if self.activeFace == nil { return }
        let figure = getFigureForId(obsId: self.activeFace!, nodes: nodes)
        let plane = getPlaneForId(obsId: self.activeFace!, nodes: nodes)
        figure.removeAnimation(forKey: "reveal")
        figure.addAnimation(createOpacityHideAnimation(fromOpacity: 1.0, toOpacity: 0.0), forKey: "disappear")
        plane.removeAnimation(forKey: "disappear")
        plane.addAnimation(createOpacityRevealAnimation(fromOpacity: 0.0, toOpacity: 0.3), forKey: "reveal")
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
            $0.value(forKey: "observationId") as! UUID == obsId     &&
            $0.value(forKey: "type") as! String == "figure"         &&
            $0.value(forKey: "root") != nil                         &&
            $0.value(forKey: "root") as! UUID == obsId
        })!
        return figure
    }
    
    func getPlaneForId(obsId: UUID, nodes: [SCNNode]) -> SCNNode {
        let plane = nodes.first(where: {
            $0.value(forKey: "observationId") as! UUID == obsId &&
            $0.value(forKey: "type") as! String == "plane"
        })!
        return plane
    }
    
    func getNodes(scene: SCNScene) -> [SCNNode] {

        // base-elements
        guard let cameraNode = scene.rootNode.childNodes.first(where: { $0.name == "Camera" }) else { return [] }
        guard let camera = cameraNode.camera else { return [] }
        // loading model
        guard let loadedScene = SCNScene(named: "Loomis_Head.usdz") else { return [] }
        let figure = loadedScene.rootNode
        
        // Size of face in meters
        let w: Float = 0.165
        let h: Float = 0.17
        
        // scaling and repositioning
        figure.scale = SCNVector3(
            x: 0.5 * w / figure.boundingSphere.radius,
            y: 0.5 * w / figure.boundingSphere.radius,
            z: 0.5 * w / figure.boundingSphere.radius
        )
        
        
        var nodes: [SCNNode] = []
        for observation in observations {
            
            // Unwrapping face-detection parameters
            let roll = Float(truncating: observation.roll!) // + Float.pi / 2.0
            let pitch = Float(truncating: observation.pitch!)
            let yaw = Float(truncating: observation.yaw!)
            let leftImg = Float(observation.boundingBox.minX)
            let rightImg = Float(observation.boundingBox.maxX)
            let topImg = Float(observation.boundingBox.maxY)
            let bottomImg = Float(observation.boundingBox.minY)
            
            let cWorld = getHeadPosition(
                w: w, h: h, ar: Float(imageSize.width) / Float(imageSize.height),
                topImg: topImg, rightImg: rightImg, bottomImg: bottomImg, leftImg: leftImg,
                projectionTransform: camera.projectionTransform,
                viewTransform: SCNMatrix4Invert(cameraNode.transform)
            )
            
            let f = figure.clone()
            
            f.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
            f.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            f.opacity = 0.0
            f.setValue(observation.uuid, forKey: "root")
            setValueRecursively(node: f, val: "figure", key: "type")
            setValueRecursively(node: f, val: observation.uuid, key: "observationId")
            
            let plane = SCNNode(geometry: SCNPlane(width: CGFloat(w), height: CGFloat(h)))
            plane.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            plane.opacity = 0.3
            plane.setValue("plane", forKey: "type")
            plane.setValue(observation.uuid, forKey: "observationId")
            
            nodes.append(f)
            nodes.append(plane)
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
            
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .border(.green)
            
            HeadView(
                observations: [observation1, observation2],
                imageSize: size
            ).border(.red)
            
        }.frame(width: w, height: h)
    }
}
