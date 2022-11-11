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
    
    // width of head in meters
    private var w: Float = 0.25
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
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "Camera"
        scene.rootNode.addChildNode(cameraNode)
        
        // Plane - facing the camera directly
        let w = w
        let h = 1.2 * w
        let tlPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let trPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let brPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        let blPoint = SCNNode(geometry: SCNSphere(radius: 0.1))
        tlPoint.position = SCNVector3(x: -w/2.0, y:  h/2.0, z: 0)
        trPoint.position = SCNVector3(x:  w/2.0, y:  h/2.0, z: 0)
        brPoint.position = SCNVector3(x:  w/2.0, y: -h/2.0, z: 0)
        blPoint.position = SCNVector3(x: -w/2.0, y: -h/2.0, z: 0)
        let planeNode = SCNNode()
        planeNode.addChildNode(tlPoint)
        planeNode.addChildNode(trPoint)
        planeNode.addChildNode(brPoint)
        planeNode.addChildNode(blPoint)
        scene.rootNode.addChildNode(planeNode)
        planeNode.position = SCNVector3(x: 1, y: 1, z: -3)
        planeNode.look(at: cameraNode.position)
        tlPoint.name = "tl"
        trPoint.name = "tr"
        brPoint.name = "br"
        blPoint.name = "bl"
        planeNode.name = "Plane"
        
        // projecting plane onto 2d-image-space
        let tlWorld = tlPoint.worldPosition
        let trWorld = trPoint.worldPosition
        let brWorld = brPoint.worldPosition
        let blWorld = blPoint.worldPosition
        let tlImgCoords = sceneView.projectPoint(tlWorld)
        let trImgCoords = sceneView.projectPoint(trWorld)
        let brImgCoords = sceneView.projectPoint(brWorld)
        let blImgCoords = sceneView.projectPoint(blWorld)
        
        self.topImg = tlImgCoords.y / Float(self.hImg)
        self.rightImg = trImgCoords.x / Float(self.wImg)
        self.bottomImg = brImgCoords.y / Float(self.hImg)
        self.leftImg = blImgCoords.x / Float(self.wImg)
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
            w: w, arImg: arImg, arCam: arCam,
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
