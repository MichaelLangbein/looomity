//
//  HeadView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit



struct HeadView : UIViewRepresentable {
    
    // Parameters for a detected face
    var observation: VNFaceObservation
    // Aspect-ratio of underlying photo
    var imageSize: CGSize
    // Called after each rendered frame
    var onRender: ((SCNSceneRenderer, SCNView) -> Void)?
    
    // Needs to remain in scope
    let sceneView = SCNView()

    func makeUIView(context: Context) -> SCNView {
        // Having swiftui connect scene-view with the coordinator
        self.sceneView.delegate = context.coordinator
        
        // Unwrapping face-detection parameters
        let roll = Float(truncating: observation.roll!)
        let pitch = Float(truncating: observation.pitch!)
        let yaw = Float(truncating: observation.yaw!)
        let leftImg = Float(observation.boundingBox.minX)
        let rightImg = Float(observation.boundingBox.maxX)
        let topImg = Float(observation.boundingBox.maxY)
        let bottomImg = Float(observation.boundingBox.minY)

        // Scene
        let scene = SCNScene()

        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        cameraNode.camera = camera

        // Size of head in meters
        let w: Float = 0.25
        
        // aspect-ratio's
        let arImg = Float(imageSize.width / imageSize.height)
        let sceneFrame = self.sceneView.frame
        let arCam = Float(sceneFrame.width / sceneFrame.height)
        
        let cWorld = getHeadPosition(
            w: w,
            arImg: arImg, arCam: arCam,
            topImg: topImg, rightImg: rightImg, bottomImg: bottomImg, leftImg: leftImg,
            projectionTransform: camera.projectionTransform, viewTransform: SCNMatrix4Invert(cameraNode.transform)
        )
        
        // ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "Light"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)

        // loading model
        guard let loadedScene = SCNScene(named: "Loomis_Head.usdz") else {
            return SCNView()
        }
        let figure = loadedScene.rootNode
        
        // make white transparent for background,
        // while still obscuring model elements
         applyCustomShader(figure)
//        let postprocessor = SCNTechnique(dictionary: [
//            "passes": [
//                "draw": "DRAW_SCENE",
//                "program": "whiteToTransparent"
//            ]
//        ])
        
        // scaling and repositioning
        figure.scale = SCNVector3(
            x: w / figure.boundingSphere.radius,
            y: w / figure.boundingSphere.radius,
            z: w / figure.boundingSphere.radius
        )
        figure.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
        figure.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
        figure.name = "Head"
        scene.rootNode.addChildNode(figure)

        // scene
        self.sceneView.scene = scene
        self.sceneView.allowsCameraControl = true
        self.sceneView.cameraControlConfiguration.allowsTranslation = true
        self.sceneView.backgroundColor = UIColor.clear
        return self.sceneView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        print("Update called")
    }
    
    // allowing user to hook into render loop
    func makeCoordinator() -> RenderDelegate {
        return RenderDelegate(parent: self)
    }
    final class RenderDelegate: NSObject, SCNSceneRendererDelegate {
        var parent: HeadView
        init(parent: HeadView) {
            self.parent = parent
        }
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            if let callback = self.parent.onRender {
                callback(renderer, parent.sceneView)
            }
        }
    }
}


/// Calculate world-coordinates of head
/// - parameter w: width of head in meters
/// - parameter arImg: aspect ratio of underlying image
/// - parameter arCam: aspect ratio of scene
func getHeadPosition(
    w: Float, arImg: Float, arCam: Float,
    topImg: Float, rightImg: Float, bottomImg: Float, leftImg: Float,
    projectionTransform: SCNMatrix4, viewTransform: SCNMatrix4
) -> SCNVector4 {
    
    //----------------------------
    // Calculating head-position
    //----------------------------
    
    
    // Face-bbox: from relative-image-coordinates to clipspace-x and y.
    let top     = (2.0 * topImg     - 1.0) * arCam / arImg;
    let bottom  = (2.0 * bottomImg  - 1.0) * arCam / arImg;
    let right   = (2.0 * rightImg   - 1.0) * arImg / arCam;
    let left    = (2.0 * leftImg    - 1.0) * arImg / arCam;
    
    // Placing face-bbox in clip-space [x, y, 1, 1]
    let tl = imageSpace2ClipSpace(left, top)
    let tr = imageSpace2ClipSpace(right, top)
    let br = imageSpace2ClipSpace(right, bottom)
    let bl = imageSpace2ClipSpace(left, bottom)
    
    // Getting central point c. A ray will be cast through c to the head's actual position
    let aClip = midpoint(tl, bl)
    let bClip = midpoint(tr, br)
    let cClip = midpoint(aClip, bClip)
    
    // Projecting out of clipping space into camera space.
    // Accounts for focal length, near and far, and other camera-parameters.
    // Results are not points, but directions (their w == 1)
    let projectionInverse = SCNMatrix4Invert(projectionTransform)
    let a = matMul(projectionInverse, aClip)  // direction towards point a
    let b = matMul(projectionInverse, bClip)  // direction towards point b
    let c = matMul(projectionInverse, cClip)  // direction towards point c
    
    let magA = magnitude(a)
    let magB = magnitude(b)
    let magC = magnitude(c)
    
    // Angle between a and b.
    // Used to calculate at what distance from origin the head must be.
    // Assumes that the head-bounding-box is orthogonal to the ray towards c.
    let sigma = acos( dot(a, b) / (magA * magB) )
    let l = w / (2.0 * tan(sigma / 2.0))
    
    // Scaling normalized c by l
    let cNorm = scalarProd(1.0 / magC, c)
    let cCam = scalarProd(l, cNorm)
    
    // Transforming out of camera-space into world-space
    let viewInverse = SCNMatrix4Invert(viewTransform)
    let cWorld = matMul(viewInverse, cCam)
    
    return cWorld
}

func matMul(_ matrix: SCNMatrix4, _ vector: SCNVector4) -> SCNVector4 {
    
    // matrices in Scenekit are OpenGL-oriented ... that is: column/row
    let row1 = SCNVector4(x: matrix.m11, y: matrix.m21, z: matrix.m31, w: matrix.m41)
    let row2 = SCNVector4(x: matrix.m12, y: matrix.m22, z: matrix.m32, w: matrix.m42)
    let row3 = SCNVector4(x: matrix.m13, y: matrix.m23, z: matrix.m33, w: matrix.m43)
    let row4 = SCNVector4(x: matrix.m14, y: matrix.m24, z: matrix.m34, w: matrix.m44)
    
    let x = dot(row1, vector)
    let y = dot(row2, vector)
    let z = dot(row3, vector)
    let w = dot(row4, vector)

    return SCNVector4(
        x: x, y: y, z: z, w: w
    )
}

func imageSpace2ClipSpace(_ x: Float, _ y: Float) -> SCNVector4 {
    return SCNVector4(
        x: x,
        y: y,
        z: 1,
        w: 1
    )
}


func midpoint(_ v1: SCNVector4, _ v2: SCNVector4) -> SCNVector4 {
    return SCNVector4(
        x: (v1.x + v2.x) / 2.0,
        y: (v1.y + v2.y) / 2.0,
        z: (v1.z + v2.z) / 2.0,
        w: 1
    )
}

func dot(_ v1: SCNVector4, _ v2: SCNVector4) -> Float {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w
}

func magnitude(_ v: SCNVector4) -> Float {
    return sqrtf(dot(v, v))
}

func scalarProd(_ scalar: Float, _ vec: SCNVector4) -> SCNVector4 {
    return SCNVector4(
        x: scalar * vec.x,
        y: scalar * vec.y,
        z: scalar * vec.z,
        w: scalar * vec.w
    )
}


func applyCustomShader(_ node: SCNNode) {
    node.geometry?.firstMaterial?.transparencyMode = .aOne
    node.geometry?.shaderModifiers = [
        SCNShaderModifierEntryPoint.fragment : """
            #pragma transparent
            #pragma body
            float whiteness = (_output.color.r + _output.color.g + _output.color.b) / 3.0;
            // both rgb and a range from 0 to 1
            // a = 0.0: transparent
            // a = 1.0: opaque
            _output.color.a = 1.0 - whiteness;
        """
    ]
    for child in node.childNodes {
        applyCustomShader(child)
    }
}


struct HeadView_Previews: PreviewProvider {
    static var previews: some View {
        let observation = VNFaceObservation(
            requestRevision: 0,
            boundingBox: CGRect(x: 0.4, y: 0.75, width: 0.125, height: 0.125),
            roll: 0.3,
            yaw: 0.01,
            pitch: -0.3
        )
        
        let img = UIImage(named: "TestImage")
        let size = img!.size
        
        return ZStack {
            Image(uiImage: img!)
                .resizable()
                .scaledToFit()
                .border(.green)
            HeadView(observation: observation, imageSize: size) { renderer, sceneView in
                print("rendering ...")
            }.border(.red)
        }.frame(width: 0.9 * size.width, height: 0.9 * size.height)
    }
}
