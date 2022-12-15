//
//  BoxPlacementTest.swift
//  Looomity
//
//  Created by Michael Langbein on 11.11.22.
//

import XCTest
import SceneKit
@testable import Looomity


final class BoxPlacementTests: XCTestCase {
    
    // dimensions of head in meters
    private var w: Float = 0.25
    private var h: Float = 0.30
    // image dimensions
    private var wImg = 300
    private var hImg = 450
    // sceneView
    private var sceneView: SCNView!
    // bbox
    private var topImg: Float!
    private var rightImg: Float!
    private var bottomImg: Float!
    private var leftImg: Float!


    override func setUp() {
        // sceneView
        self.sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: wImg, height: hImg))
        
        // Scene
        let scene = SCNScene()
        sceneView.scene = scene

        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.usesOrthographicProjection = false
        camera.projectionDirection = self.hImg > self.wImg ? .vertical : .horizontal
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        // Plane - facing the camera directly
        let tlPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let trPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let brPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let blPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        tlPoint.position = SCNVector3(x: -w/2.0, y:  h/2.0, z: 0)
        trPoint.position = SCNVector3(x:  w/2.0, y:  h/2.0, z: 0)
        brPoint.position = SCNVector3(x:  w/2.0, y: -h/2.0, z: 0)
        blPoint.position = SCNVector3(x: -w/2.0, y: -h/2.0, z: 0)
        let planeNode = SCNNode()
        planeNode.look(at: SCNVector3(x: 0, y: 0, z: 1))
        planeNode.addChildNode(tlPoint)
        planeNode.addChildNode(trPoint)
        planeNode.addChildNode(brPoint)
        planeNode.addChildNode(blPoint)
        planeNode.position = SCNVector3(x: 1, y: 3, z: -3)
        planeNode.look(at: cameraNode.position)
        scene.rootNode.addChildNode(planeNode)
        
        tlPoint.name = "tl"
        trPoint.name = "tr"
        brPoint.name = "br"
        blPoint.name = "bl"
        planeNode.name = "Plane"
        
        // projecting plane onto 2d-image-space
        // seems that plane was flipped around y axis ...
        // ... formerly left points are now right
        let trWorld = tlPoint.worldPosition
        let tlWorld = trPoint.worldPosition
        let blWorld = brPoint.worldPosition
        let brWorld = blPoint.worldPosition
        
        // image coordinates are:
        // x: left(0) -> right(high)
        // y: top(0) -> bottom(high)
        let blImgCoords = sceneView.projectPoint(tlWorld)
        let brImgCoords = sceneView.projectPoint(trWorld)
        let trImgCoords = sceneView.projectPoint(brWorld)
        let tlImgCoords = sceneView.projectPoint(blWorld)
        
        self.topImg     = 1.0 - min(tlImgCoords.y, trImgCoords.y, blImgCoords.y, brImgCoords.y) / Float(self.hImg)
        self.rightImg   = max(tlImgCoords.x, trImgCoords.x, blImgCoords.x, brImgCoords.x) / Float(self.wImg)
        self.bottomImg  = 1.0 - max(tlImgCoords.y, trImgCoords.y, blImgCoords.y, brImgCoords.y) / Float(self.hImg)
        self.leftImg    = min(tlImgCoords.x, trImgCoords.x, blImgCoords.x, brImgCoords.x) / Float(self.wImg)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlacement() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        setUp()
        
        let arImg = Float(self.wImg) / Float(self.hImg)
        let frame = self.sceneView.frame
        let arCam = Float(frame.width) / Float(frame.height)
        
        let cameraNode = self.sceneView.scene!.rootNode.childNode(withName: "Camera", recursively: true)!
        let plane = self.sceneView.scene!.rootNode.childNode(withName: "Plane", recursively: true)!
        let camera = cameraNode.camera!
        let planePos = plane.worldPosition
        
        let cWorld = getHeadPosition(
            w: w, h: h, ar: arImg,
            topImg: topImg, rightImg: rightImg, bottomImg: bottomImg, leftImg: leftImg,
            projectionTransform: camera.projectionTransform, viewTransform: SCNMatrix4Invert(cameraNode.transform)
        )
        
        XCTAssert(diff(cWorld.x, planePos.x) < 0.2)
        XCTAssert(diff(cWorld.y, planePos.y) < 0.2)
        XCTAssert(diff(cWorld.z, planePos.z) < 0.2)
    }
    
    func diff(_ a: Float, _ b: Float) -> Float {
        return abs(a - b)
    }

}
