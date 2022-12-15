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
    
    var body: some View {
        
        SceneKitView(
            width: Int(imageSize.width),
            height: Int(imageSize.height),
            loadNodes: { view, scene, camera in
                return self.getNodes(scene: scene)
            }
        )
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
            f.opacity = 0.05
            
            let plane = SCNNode(geometry: SCNPlane(width: CGFloat(w), height: CGFloat(h)))
            plane.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
            plane.opacity = 0.3
            
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
