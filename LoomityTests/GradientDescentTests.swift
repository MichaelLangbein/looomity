//
//  GradientDescentTests.swift
//  LooomityTests
//
//  Created by Michael Langbein on 11.11.22.
//

import XCTest
import SwiftUI
@testable import Loomity


func f(x: [Float]) -> Float {
    return 1.0 - pow(x[0] - 4.0, 3.0) + pow(x[1] - 1.0, 2.0)
}

final class GradientDescentTests: XCTestCase {

    
    func setUpWithError() async throws {
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

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
