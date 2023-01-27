//
//  GradientDescentIntegrationTests.swift
//  LoomityTests
//
//  Created by Michael Langbein on 22.01.23.
//

import XCTest
import SceneKit
import Vision
@testable import Loomity


final class GradientDescentIntegrationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testDetection() throws {
        let expectation = expectation(description: "Expects a face to be detected in test-image")
        let image = UIImage(named: "TestImage")!
        detectFacesWithLandmarks(uiImage: image) { observations in
            if observations.count > 0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 20)
    }
    
    private var observations: [VNFaceObservation] = []
    
    func testOnRealImage() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let expectation = expectation(description: "Expects optimised models to be placed better than non-optimized ones.")

        let image = UIImage(named: "TestImage")!
        
        let sceneController = SceneController(
            screen_width: 400,
            screen_height: 600,
            image_width: image.size.width,
            image_height: image.size.height,
            loadNodes: { view, scene, camera in
                let loadedScene = SCNScene(named: "loomisNew.usdz")!
                let figure = loadedScene.rootNode
                
                var nodes: [SCNNode] = []
                let ar = Float(image.size.width / image.size.height)
                    
                // Unwrapping face-detection parameters
                for observation in self.observations {

                    let roll  = Float(truncating: observation.roll!)
                    let pitch = Float(truncating: observation.pitch!)
                    let yaw   = Float(truncating: observation.yaw!)
                    
                    let leftImg   = Float(observation.boundingBox.minX)
                    let rightImg  = Float(observation.boundingBox.maxX)
                    let topImg    = Float(observation.boundingBox.maxY)
                    let bottomImg = Float(observation.boundingBox.minY)
                    
                    let wImg   = rightImg - leftImg
                    let hImg   = topImg - bottomImg
                    let xImg   = leftImg   + wImg / 2.0
                    let yImg   = bottomImg + hImg / 2.0
                    let xScene = 2.0 * xImg - 1.0
                    let yScene = (2.0 * yImg - 1.0) * Float(ar)
                    let cWorld = SCNVector3(x: xScene, y: yScene, z: 0)
                    
                    // we only use width for scale factor because face-detection doesn't include forehead,
                    // rendering the height-value useless for scaling.
                    let scaleFactor = 3.0 * 1.3 * (wImg) / figure.boundingSphere.radius
                    figure.scale = SCNVector3( x: scaleFactor, y: scaleFactor, z: scaleFactor )
                    figure.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
                    figure.position = SCNVector3(x: cWorld.x, y: cWorld.y, z: cWorld.z)
                    
                    let fOptimized = gradientDescent(sceneView: view, head: figure, observation: observation, image: image)
                    
                    XCTAssert(fOptimized.position.x != cWorld.x)
                    XCTAssert(fOptimized.position.y != cWorld.y)
                    XCTAssert(fOptimized.position.z == cWorld.z)  // no change in z-coordinate
                    expectation.fulfill()
                    
                    nodes.append(fOptimized)
                }
                return nodes
            }
        )

        detectFacesWithLandmarks(uiImage: image) { observations in
            self.observations = observations
            sceneController.viewDidLoad()
        }
        
        wait(for: [expectation], timeout: 20)
    }


    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
