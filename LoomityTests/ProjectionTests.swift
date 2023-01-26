//
//  ProjectionTests.swift
//  LoomityTests
//
//  Created by Michael Langbein on 26.01.23.
//

import XCTest
import SceneKit
@testable import Loomity


final class ProjectionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func _doTestProjection(screenWidth: CGFloat, screenHeight: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat, cameraWorldTransform: SCNMatrix4, cameraProjectionTransform: SCNMatrix4) {
        
        let ar = imageWidth / imageHeight
        
        let pointTopLeft = SCNVector3(x: -1.0, y: 1.0 / Float(ar), z: 0.0)
        let pointTopLeftProjected = scene2imagePerspective(
            pointTopLeft,
            imageWidth, imageHeight,
            screenWidth, screenHeight,
            cameraWorldTransform, cameraProjectionTransform
        )
        _assertCloseTo(pointTopLeftProjected.x, 0.0)
        _assertCloseTo(pointTopLeftProjected.y, 1.0)
        
        let pointTopRight = SCNVector3(x: 1.0, y: 1.0 / Float(ar), z: 0.0)
        let pointTopRightProjected = scene2imagePerspective(
            pointTopRight,
            imageWidth, imageHeight,
            screenWidth, screenHeight,
            cameraWorldTransform, cameraProjectionTransform
        )
        _assertCloseTo(pointTopRightProjected.x, 1.0)
        _assertCloseTo(pointTopRightProjected.y, 1.0)
        
        let pointBottomRight = SCNVector3(x: 1.0, y: -1.0 / Float(ar), z: 0.0)
        let pointBottomRightProjected = scene2imagePerspective(
            pointBottomRight,
            imageWidth, imageHeight,
            screenWidth, screenHeight,
            cameraWorldTransform, cameraProjectionTransform
        )
        _assertCloseTo(pointBottomRightProjected.x, 1.0)
        _assertCloseTo(pointBottomRightProjected.y, 0.0)
        
        
        let pointBottomLeft = SCNVector3(x: -1.0, y: -1.0 / Float(ar), z: 0.0)
        let pointBottomLeftProjected = scene2imagePerspective(
            pointBottomLeft,
            imageWidth, imageHeight,
            screenWidth, screenHeight,
            cameraWorldTransform, cameraProjectionTransform
        )
        _assertCloseTo(pointBottomLeftProjected.x, 0.0)
        _assertCloseTo(pointBottomLeftProjected.y, 0.0)
    }
    
    func testProjection_PhonePortrait_ImagePortrait() throws {
        let screenWidth: CGFloat = 414
        let screenHeight: CGFloat = 736
        let imageWidth: CGFloat = 1080
        let imageHeight: CGFloat = 1920
        let cameraWorldTransform = SCNMatrix4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 3.46410155, m44: 1
        )
        let cameraProjectionTransform = SCNMatrix4(
            m11: 1.73205078, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1.73205078, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: -1.0002, m34: -1,
            m41: 0, m42: 0, m43: -1, m44: 0
        )
        _doTestProjection(screenWidth: screenWidth, screenHeight: screenHeight, imageWidth: imageWidth, imageHeight: imageHeight, cameraWorldTransform: cameraWorldTransform, cameraProjectionTransform: cameraProjectionTransform)
    }
    
    func testProjection_PhonePortrait_ImageLandscape() throws {
        let screenWidth: CGFloat = 414
        let screenHeight: CGFloat = 736
        let imageWidth: CGFloat = 1920
        let imageHeight: CGFloat = 1080
        let cameraWorldTransform = SCNMatrix4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 3.46410155, m44: 1
        )
        let cameraProjectionTransform = SCNMatrix4(
            m11: 1.73205078, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1.73205078, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: -1.0002, m34: -1,
            m41: 0, m42: 0, m43: -1, m44: 0
        )
        _doTestProjection(screenWidth: screenWidth, screenHeight: screenHeight, imageWidth: imageWidth, imageHeight: imageHeight, cameraWorldTransform: cameraWorldTransform, cameraProjectionTransform: cameraProjectionTransform)
    }
    
    func testProjection_PhoneLandscape_ImageLandscape() throws {
        let screenWidth: CGFloat = 736
        let screenHeight: CGFloat = 736
        let imageWidth: CGFloat = 1920
        let imageHeight: CGFloat = 1080
        let cameraWorldTransform = SCNMatrix4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 3.46410155, m44: 1
        )
        let cameraProjectionTransform = SCNMatrix4(
            m11: 1.73205078, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1.73205078, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: -1.0002, m34: -1,
            m41: 0, m42: 0, m43: -1, m44: 0
        )
        _doTestProjection(screenWidth: screenWidth, screenHeight: screenHeight, imageWidth: imageWidth, imageHeight: imageHeight, cameraWorldTransform: cameraWorldTransform, cameraProjectionTransform: cameraProjectionTransform)
    }
    
    func testProjection_PhoneLandscape_ImagePortrait() throws {
        let screenWidth: CGFloat = 736
        let screenHeight: CGFloat = 736
        let imageWidth: CGFloat = 1080
        let imageHeight: CGFloat = 1920
        let cameraWorldTransform = SCNMatrix4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 3.46410155, m44: 1
        )
        let cameraProjectionTransform = SCNMatrix4(
            m11: 1.73205078, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1.73205078, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: -1.0002, m34: -1,
            m41: 0, m42: 0, m43: -1, m44: 0
        )
        _doTestProjection(screenWidth: screenWidth, screenHeight: screenHeight, imageWidth: imageWidth, imageHeight: imageHeight, cameraWorldTransform: cameraWorldTransform, cameraProjectionTransform: cameraProjectionTransform)
    }
    
    func _assertCloseTo(_ actualValue: Double, _ targetValue: Double, _ delta: Double = 0.06, _ message: String? = "") {
        assert(targetValue - delta < actualValue, "Value \(actualValue) is smaller than target \(targetValue). \(message ?? "")")
        assert(actualValue < targetValue + delta,  "Value \(actualValue) is bigger than target \(targetValue). \(message ?? "")")
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
