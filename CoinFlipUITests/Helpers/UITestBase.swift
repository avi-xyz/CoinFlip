//
//  UITestBase.swift
//  CoinFlipUITests
//
//  Base class for all UI tests with common setup, helpers, and assertions
//

import XCTest

class UITestBase: XCTestCase {

    var app: XCUIApplication!
    let reporter = TestReporter.shared

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = [
            "RESET_STATE": "1",  // Sign out and clear state for fresh test
            "AUTO_CREATE_TEST_USER": "1"  // Automatically create test user for existing tests
        ]
        app.launch()

        // Give app time to complete RESET_STATE sign out
        sleep(2)

        // Wait for app to fully initialize
        // Sequence: RESET_STATE sign out → anonymous sign in → auto-create user → main app
        // Auto user creation takes a moment (sign in + create profile + create portfolio)
        // Wait for tab bar to appear (indicates app is ready and user is created)
        let tabBar = app.tabBars.firstMatch
        let tabBarAppeared = tabBar.waitForExistence(timeout: 30)

        if !tabBarAppeared {
            // If tab bar didn't appear, might be stuck at onboarding
            print("⚠️ Tab bar did not appear - might be stuck at onboarding")
            // Try to detect if we're on username setup screen
            let usernameField = app.textFields["usernameTextField"]
            if usernameField.exists {
                print("❌ Still on username setup screen - auto-create failed!")
            }
        }

        // Give additional time for data to load
        sleep(3)

        reporter.startTest(testName)
    }

    override func tearDownWithError() throws {
        // Take screenshot on failure
        if let testRun = testRun, testRun.failureCount > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        reporter.endTest(testName, passed: testRun?.failureCount == 0)

        app.terminate()
        app = nil

        try super.tearDownWithError()
    }

    // MARK: - Test Name Helper

    var testName: String {
        return name.components(separatedBy: " ").last?.replacingOccurrences(of: "]", with: "") ?? "Unknown Test"
    }

    // MARK: - Navigation Helpers

    func navigateToTab(_ tab: Tab) {
        let tabButton = app.tabBars.buttons[tab.rawValue]
        tabButton.tapAfterWaiting(timeout: 5)
    }

    enum Tab: String {
        case home = "Home"
        case portfolio = "Portfolio"
        case leaderboard = "Leaderboard"
        case profile = "Profile"
    }

    // MARK: - Common Element Accessors

    var homeTab: XCUIElement { app.tabBars.buttons["Home"] }
    var portfolioTab: XCUIElement { app.tabBars.buttons["Portfolio"] }
    var leaderboardTab: XCUIElement { app.tabBars.buttons["Leaderboard"] }
    var profileTab: XCUIElement { app.tabBars.buttons["Profile"] }

    // MARK: - Wait Helpers

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    // MARK: - Enhanced Assertions

    func assertElementExists(
        _ element: XCUIElement,
        _ message: String = "",
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        reporter.recordAssertion(testName: testName)

        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            let errorMessage = message.isEmpty ? "Element '\(element.identifier)' should exist" : message
            XCTFail(errorMessage, file: file, line: line)

            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Element not found: \(element.identifier)",
                expectedBehavior: "Element should exist and be visible",
                actualBehavior: "Element was not found within \(timeout) seconds",
                stepsToReproduce: getCurrentTestSteps(),
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: ["Element": element.identifier]
            )
        }
    }

    func assertElementNotExists(
        _ element: XCUIElement,
        _ message: String = "",
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        reporter.recordAssertion(testName: testName)

        sleep(UInt32(timeout))
        let exists = element.exists

        if exists {
            let errorMessage = message.isEmpty ? "Element '\(element.identifier)' should not exist" : message
            XCTFail(errorMessage, file: file, line: line)

            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Unexpected element found: \(element.identifier)",
                expectedBehavior: "Element should not exist",
                actualBehavior: "Element was found when it shouldn't exist",
                stepsToReproduce: getCurrentTestSteps(),
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: ["Element": element.identifier]
            )
        }
    }

    func assertText(
        _ element: XCUIElement,
        contains text: String,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        reporter.recordAssertion(testName: testName)

        _ = element.waitForExistence(timeout: 5)
        let actualText = element.textValue

        if !actualText.contains(text) {
            let errorMessage = message.isEmpty ?
                "Element text '\(actualText)' should contain '\(text)'" : message

            XCTFail(errorMessage, file: file, line: line)

            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Text validation failed",
                expectedBehavior: "Element should contain text: '\(text)'",
                actualBehavior: "Element contains text: '\(actualText)'",
                stepsToReproduce: getCurrentTestSteps(),
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Element": element.identifier,
                    "Expected": text,
                    "Actual": actualText
                ]
            )
        }
    }

    func assertValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        _ message: String = "",
        allowPartialMatch: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        reporter.recordAssertion(testName: testName)

        _ = element.waitForExistence(timeout: 5)
        let actualValue = element.textValue

        let matches = allowPartialMatch ?
            actualValue.contains(expectedValue) :
            actualValue == expectedValue

        if !matches {
            let errorMessage = message.isEmpty ?
                "Value mismatch: expected '\(expectedValue)', got '\(actualValue)'" : message

            XCTFail(errorMessage, file: file, line: line)

            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .dataConsistency,
                description: "Value assertion failed",
                expectedBehavior: "Value should be: '\(expectedValue)'",
                actualBehavior: "Value is: '\(actualValue)'",
                stepsToReproduce: getCurrentTestSteps(),
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Element": element.identifier,
                    "Expected": expectedValue,
                    "Actual": actualValue
                ]
            )
        }
    }

    func assertDataConsistency(
        description: String,
        values: [String: String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        reporter.recordAssertion(testName: testName)

        // Check if all values are consistent
        let uniqueValues = Set(values.values)

        if uniqueValues.count > 1 {
            let errorMessage = "Data inconsistency detected: \(description)"
            XCTFail(errorMessage, file: file, line: line)

            var context = values
            context["Description"] = description

            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Data inconsistency across screens",
                expectedBehavior: "All values should be consistent: \(description)",
                actualBehavior: "Found inconsistent values: \(values)",
                stepsToReproduce: getCurrentTestSteps(),
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: context
            )
        }
    }

    // MARK: - Helpers

    private func getCurrentTestSteps() -> [String] {
        // This would ideally track steps throughout the test
        // For now, return a basic step structure
        return [
            "Launch app",
            "Execute test: \(testName)",
            "Assertion failed at this point"
        ]
    }

    // MARK: - Onboarding Helpers

    func completeOnboardingManually(username: String? = nil, emoji: String = "🚀") -> Bool {
        let usernameSetupScreen = UsernameSetupScreen(app: app)
        let onboardingScreen = OnboardingScreen(app: app)

        // Generate unique username if not provided
        let uniqueUsername = username ?? "UITestUser\(Int(Date().timeIntervalSince1970))"

        // Check if we're on username setup screen
        if usernameSetupScreen.verifyScreenVisible() {
            print("📝 Completing username setup with: \(uniqueUsername)")
            let success = usernameSetupScreen.completeSetup(username: uniqueUsername, emoji: emoji)
            if !success {
                print("❌ Failed to complete username setup")
                return false
            }
            print("✅ Username setup completed")
            sleep(2)
        }

        // Check if onboarding tutorial appears
        if onboardingScreen.verifyScreenVisible() {
            print("📚 Skipping onboarding tutorial...")
            let success = onboardingScreen.skipOnboarding()
            if !success {
                print("❌ Failed to skip onboarding")
                return false
            }
            print("✅ Onboarding skipped")
            sleep(2)
        }

        // Verify we're on main app
        let tabBar = app.tabBars.firstMatch
        let isOnMainApp = tabBar.waitForExistence(timeout: 5)

        if isOnMainApp {
            print("✅ Successfully reached main app")
        } else {
            print("❌ Failed to reach main app after onboarding")
        }

        return isOnMainApp
    }

    // MARK: - Common Actions

    func pullToRefresh(on element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Wait for refresh to complete
        sleep(2)
    }

    func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 5) {
        var swipeCount = 0
        while !element.isHittable && swipeCount < maxSwipes {
            app.swipeUp()
            swipeCount += 1
        }
    }

    // MARK: - Value Extraction Helpers

    func extractNumericValue(from text: String) -> Double? {
        // Extract numeric value from text like "$1,234.56" -> 1234.56
        let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    func extractCurrencyValue(from element: XCUIElement) -> Double? {
        return extractNumericValue(from: element.textValue)
    }
}
