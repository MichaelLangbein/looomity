//
//  LoomityUITests.swift
//  LoomityUITests
//
//  Created by Michael Langbein on 28.12.22.
//

import XCTest

final class LoomityUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testFullPass() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Select image"].tap()
        app.buttons["Gallery"].tap()
        app/*@START_MENU_TOKEN@*/.scrollViews.otherElements.images["Screenshot, 22. January, 08:50"]/*[[".otherElements[\"Photos\"].scrollViews.otherElements",".otherElements[\"Screenshot, 22. January, 08:50, Live Photo, 21. January, 16:06, Live Photo, 21. January, 16:06, Photo, 21. January, 13:51, Screenshot, 20. January, 17:34, Screenshot, 20. January, 17:33, Screenshot, 19. January, 22:04, Screenshot, 19. January, 21:59, Photo, 19. January, 19:00, Photo, 19. January, 18:05, Photo, 15. January, 14:47, Live Photo, 15. January, 10:38, Live Photo, 15. January, 10:38, Live Photo, 13. January, 13:42, Live Photo, 12. January, 16:03\"].images[\"Screenshot, 22. January, 08:50\"]",".images[\"Screenshot, 22. January, 08:50\"]",".scrollViews.otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
        app.buttons["Loomify"].tap()
        app.alerts["Couldn't detect any faces in your image."].scrollViews.otherElements.buttons["Continue"].tap()
        app.buttons["Add model"].tap()
        
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        element.tap()
        element.tap()
        element.tap()
        element/*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeDown()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        element.swipeRight()
        element.tap()

    }
}
