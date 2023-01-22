//
//  GradientDescentTests.swift
//  LooomityTests
//
//  Created by Michael Langbein on 11.11.22.
//

import XCTest
import SwiftUI
import SceneKit
@testable import Loomity


func f(x: [Float]) -> Float {
    return 1.0 - pow(x[0] - 4.0, 3.0) + pow(x[1] - 1.0, 2.0)
}

final class GradientDescentTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGd() {
        let initial: [Float] = [0.0, 0.0]
        let opt = gd(f: f, initial: initial)
        XCTAssert(opt.count == initial.count)
        XCTAssert(opt[0] > 3.5)
        XCTAssert(opt[0] < 4.5)
        XCTAssert(opt[1] > 0.5)
        XCTAssert(opt[1] < 1.5)
    }
    
    func testRandGd() {
        let initial: [Float] = [0.0, 0.0]
        let opt = rand_gd(f: f, initial: initial)
        XCTAssert(opt.count == initial.count)
        XCTAssert(opt[0] > 3.5)
        XCTAssert(opt[0] < 4.5)
        XCTAssert(opt[1] > 0.5)
        XCTAssert(opt[1] < 1.5)
    }

    func testOnRealImage() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let image = UIImage(named: "TestImage")!
        detectFacesWithLandmarks(uiImage: image) { observations in
            let observation = observations.first!
            
            Task {
                let sceneController = await SceneController(
                    width: 400,
                    height: 600,
                    ar: Float(image.size.width / image.size.height),
                    loadNodes: { view, scene, camera in
                        guard let loadedScene = SCNScene(named: "loomisNew.usdz") else { return [] }
                        var figure = loadedScene.rootNode
                        
                        var nodes: [SCNNode] = []
                        let ar = Float(image.size.width / image.size.height)
                            
                        // Unwrapping face-detection parameters
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
                        
                        XCTAssert(fOptimized.position.x != figure.position.x)
                        XCTAssert(fOptimized.position.y != figure.position.y)
                        XCTAssert(fOptimized.position.z != figure.position.z)
                        
                        return nodes
                    }
                )
                
                // Sets off scene-init, including `loadNodes` above.
                await sceneController.viewDidLoad()
            }
            
//            sceneController.viewDidLoad()
//            let sceneView = sceneController.sceneView
//            let nodes = sceneController.nodes
//            for observation in observations {
//                let head = nodes.first(where: <#T##(SCNNode) throws -> Bool#>)
//                let updatedHead = gradientDescent(sceneView: sceneView, head: head, observation: observation, image: image)
//            }

        }
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
