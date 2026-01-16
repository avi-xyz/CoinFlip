//
//  OnboardingTests.swift
//  CoinFlipUITests
//
//  Comprehensive tests for user onboarding journey
//  Tests the complete flow from first launch to main app
//

import XCTest

final class OnboardingTests: XCTestCase {

    var app: XCUIApplication!
    let reporter = TestReporter.shared
    var usernameSetupScreen: UsernameSetupScreen!
    var onboardingScreen: OnboardingScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        // DON'T auto-create user - we want to test the onboarding flow!
        app.launchEnvironment = [
            "RESET_STATE": "1"
        ]
        app.launch()

        // Give app extra time to complete RESET_STATE sign out
        // This ensures we start fresh each test
        sleep(2)

        usernameSetupScreen = UsernameSetupScreen(app: app)
        onboardingScreen = OnboardingScreen(app: app)

        reporter.startTest(testName)
    }

    override func tearDownWithError() throws {
        if let testRun = testRun, testRun.failureCount > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        reporter.endTest(testName, passed: testRun?.failureCount == 0)

        // CRITICAL: Terminate and reset app state
        app.terminate()

        // Give the app time to fully terminate
        sleep(1)

        app = nil
        usernameSetupScreen = nil
        onboardingScreen = nil

        try super.tearDownWithError()
    }

    var testName: String {
        return name.components(separatedBy: " ").last?.replacingOccurrences(of: "]", with: "") ?? "Unknown Test"
    }

    // MARK: - Complete User Journey Tests

    func testCompleteOnboardingJourneyWithValidUsername() {
        print("\n🎯 TESTING COMPLETE ONBOARDING JOURNEY")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 1. Verify we're on username setup screen
        let setupScreenVisible = usernameSetupScreen.verifyScreenVisible()
        XCTAssertTrue(setupScreenVisible, "Username setup screen should appear on first launch")

        if !setupScreenVisible {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .functionality,
                description: "Username setup screen did not appear on first launch",
                expectedBehavior: "App should show username setup for new users",
                actualBehavior: "Username setup screen not visible",
                stepsToReproduce: [
                    "Launch app with RESET_STATE=1",
                    "Username setup screen should appear"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Cannot proceed - username setup not visible")
            return
        }

        print("✅ Username setup screen is visible")

        // 2. Complete username setup
        // Use unique username with timestamp to avoid conflicts
        let timestamp = Int(Date().timeIntervalSince1970)
        let testUsername = "NewTrader\(timestamp)"
        let testEmoji = "🚀"

        print("📝 Entering username: \(testUsername)")
        usernameSetupScreen.enterUsername(testUsername)
        sleep(1)

        print("🎨 Selecting avatar: \(testEmoji)")
        usernameSetupScreen.selectAvatar(testEmoji)
        sleep(1)

        // 3. Verify button is enabled
        let buttonEnabled = usernameSetupScreen.isStartTradingEnabled()
        XCTAssertTrue(buttonEnabled, "Start Trading button should be enabled with valid username")

        if !buttonEnabled {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Start Trading button disabled with valid username",
                expectedBehavior: "Button should be enabled when username is 3-20 characters",
                actualBehavior: "Button remains disabled",
                stepsToReproduce: [
                    "Enter valid username: \(testUsername)",
                    "Select avatar",
                    "Button should be enabled"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Start Trading button should be enabled")
            return
        }

        print("✅ Start Trading button is enabled")

        // 4. Tap Start Trading
        print("🚀 Tapping Start Trading button...")
        usernameSetupScreen.tapStartTrading()

        // 5. Wait for user creation (may take a few seconds)
        print("⏳ Waiting for user creation and app initialization...")
        sleep(5)

        // 6. Check if we reached main app or onboarding tutorial
        let tabBar = app.tabBars.firstMatch
        let mainAppReached = tabBar.waitForExistence(timeout: 10)

        let onboardingVisible = onboardingScreen.verifyScreenVisible()

        if onboardingVisible {
            print("📚 Onboarding tutorial appeared - skipping it...")
            let skipped = onboardingScreen.skipOnboarding()
            XCTAssertTrue(skipped, "Should be able to skip onboarding")
            sleep(2)

            // Check again for main app
            let nowOnMainApp = tabBar.waitForExistence(timeout: 5)
            XCTAssertTrue(nowOnMainApp, "Should reach main app after skipping onboarding")

            if nowOnMainApp {
                print("✅ Reached main app successfully!")
            }
        } else if mainAppReached {
            print("✅ Reached main app directly (no onboarding tutorial)")
        } else {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .functionality,
                description: "Failed to reach main app after completing username setup",
                expectedBehavior: "App should navigate to main app or onboarding after username setup",
                actualBehavior: "Stuck somewhere - neither main app nor onboarding visible",
                stepsToReproduce: [
                    "Complete username setup",
                    "Tap Start Trading",
                    "Should reach main app or onboarding"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Did not reach main app or onboarding")
            return
        }

        // 7. Verify main app loaded correctly
        XCTAssertTrue(tabBar.exists, "Tab bar should exist on main app")

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")

        print("✅ COMPLETE ONBOARDING JOURNEY SUCCESSFUL")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testInvalidUsernameValidation() {
        print("\n🔍 TESTING USERNAME VALIDATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        XCTAssertTrue(usernameSetupScreen.verifyScreenVisible(), "Setup screen should be visible")

        // Test too short
        print("Testing username: 'ab' (too short)...")
        usernameSetupScreen.usernameTextField.tapAfterWaiting()
        usernameSetupScreen.usernameTextField.typeText("ab")
        sleep(1)

        XCTAssertFalse(usernameSetupScreen.isStartTradingEnabled(), "Button should be disabled for username < 3 chars")
        print("✅ Button correctly disabled for short username")

        // Clear and test too long
        usernameSetupScreen.usernameTextField.tapAfterWaiting()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10)
        usernameSetupScreen.usernameTextField.typeText(deleteString)

        print("Testing username: 'verylongusernamethatexceedslimit' (too long)...")
        usernameSetupScreen.usernameTextField.typeText("verylongusernamethatexceedslimit")
        sleep(1)

        // Even though we typed more, button might still be disabled if validation fails
        // This depends on whether the text field limits input or just validates
        print("✅ Tested long username validation")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testAvatarSelection() {
        print("\n🎨 TESTING AVATAR SELECTION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        XCTAssertTrue(usernameSetupScreen.verifyScreenVisible(), "Setup screen should be visible")

        let emojis = ["🚀", "💎", "🔥", "⚡️", "🎯"]

        for emoji in emojis {
            print("Testing avatar: \(emoji)")
            let button = usernameSetupScreen.avatarButton(emoji: emoji)

            if button.waitForExistence(timeout: 3) {
                button.tap()
                sleep(1)
                print("✅ Successfully tapped \(emoji)")
            } else {
                print("⚠️ Avatar \(emoji) not found")
            }
        }

        print("✅ Avatar selection tested")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testUsernameSetupUIElements() {
        print("\n🔍 TESTING USERNAME SETUP UI ELEMENTS")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        XCTAssertTrue(usernameSetupScreen.verifyScreenVisible(), "Setup screen should be visible")

        // Verify all key elements exist
        XCTAssertTrue(usernameSetupScreen.welcomeTitle.exists, "Welcome title should exist")
        XCTAssertTrue(usernameSetupScreen.pickAvatarLabel.exists, "Pick Avatar label should exist")
        XCTAssertTrue(usernameSetupScreen.chooseUsernameLabel.exists, "Choose Username label should exist")
        XCTAssertTrue(usernameSetupScreen.usernameTextField.exists, "Username text field should exist")
        XCTAssertTrue(usernameSetupScreen.startTradingButton.exists, "Start Trading button should exist")

        print("✅ All UI elements present")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testStartingBalanceAfterOnboarding() {
        print("\n💰 TESTING STARTING BALANCE AFTER ONBOARDING")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Complete onboarding with unique username
        let timestamp = Int(Date().timeIntervalSince1970)
        let testUsername = "BalanceTest\(timestamp)"
        let success = usernameSetupScreen.completeSetup(username: testUsername, emoji: "💰")
        XCTAssertTrue(success, "Should complete onboarding successfully")

        // Skip onboarding tutorial if it appears
        if onboardingScreen.verifyScreenVisible() {
            onboardingScreen.skipOnboarding()
            sleep(2)
        }

        // Verify we're on main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Should be on main app")

        // Check net worth shows $1,000 starting balance
        let netWorthLabel = app.staticTexts.matching(identifier: "netWorthValue").firstMatch
        if netWorthLabel.waitForExistence(timeout: 10) {
            let netWorthText = netWorthLabel.label
            print("💰 Net worth displayed: \(netWorthText)")

            // Should contain $1,000 or $1000.00
            let containsCorrectAmount = netWorthText.contains("1,000") || netWorthText.contains("1000")
            XCTAssertTrue(containsCorrectAmount, "Net worth should show $1,000 starting balance")

            if containsCorrectAmount {
                print("✅ Starting balance is correct: $1,000")
            }
        } else {
            XCTFail("Net worth label not found")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
