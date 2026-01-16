//
//  SimpleTest.swift
//  CoinFlipUITests
//
//  Minimal test to verify test target is working
//

import XCTest

final class SimpleTest: XCTestCase {

    func testExample() {
        let app = XCUIApplication()
        app.launch()

        // Just verify the app launches
        XCTAssert(true, "App launched successfully")

        print("✅ Simple test passed - test target is working!")
    }
}
