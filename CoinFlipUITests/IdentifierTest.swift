//
//  IdentifierTest.swift
//  CoinFlipUITests
//
//  Test to verify accessibility identifiers are working
//

import XCTest

final class IdentifierTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(3) // Wait for app to fully load
    }

    func testNetWorthIdentifierExists() {
        print("\n🔍 Testing if netWorthValue identifier exists")

        let netWorthElement = app.staticTexts.matching(identifier: "netWorthValue").firstMatch

        if netWorthElement.waitForExistence(timeout: 10) {
            print("✅ Found netWorthValue: \(netWorthElement.label)")
            XCTAssertTrue(true)
        } else {
            print("❌ Could not find netWorthValue identifier")
            print("All static texts:")
            for element in app.staticTexts.allElementsBoundByIndex {
                if element.exists {
                    print("  - \(element.identifier): \(element.label)")
                }
            }
            XCTFail("netWorthValue identifier not found")
        }
    }

    func testNavigateToPortfolio() {
        print("\n🔍 Testing navigation to Portfolio screen")

        let portfolioTab = app.tabBars.buttons["Portfolio"]

        if portfolioTab.waitForExistence(timeout: 5) {
            print("✅ Found Portfolio tab")
            portfolioTab.tap()
            sleep(2)

            let portfolioNetWorth = app.staticTexts.matching(identifier: "portfolioNetWorth").firstMatch

            if portfolioNetWorth.waitForExistence(timeout: 5) {
                print("✅ Found portfolioNetWorth: \(portfolioNetWorth.label)")
                XCTAssertTrue(true)
            } else {
                print("❌ Could not find portfolioNetWorth identifier")
                XCTFail("portfolioNetWorth identifier not found after navigation")
            }
        } else {
            print("❌ Could not find Portfolio tab")
            XCTFail("Portfolio tab not found")
        }
    }
}
