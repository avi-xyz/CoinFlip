//
//  ProfileScreenTests.swift
//  CoinFlipUITests
//
//  Comprehensive tests for Profile Screen functionality
//

import XCTest

final class ProfileScreenTests: UITestBase {

    var profileScreen: ProfileScreen!
    var homeScreen: HomeScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()
        profileScreen = ProfileScreen(app: app)
        homeScreen = HomeScreen(app: app)
    }

    override func tearDownWithError() throws {
        profileScreen = nil
        homeScreen = nil
        try super.tearDownWithError()
    }

    // MARK: - Initial State Tests

    func testProfileScreenInitialLoad() {
        profileScreen.navigate()

        assertElementExists(profileScreen.usernameLabel, "Username should be visible")
        assertElementExists(profileScreen.netWorthLabel, "Net worth should be visible")
        assertElementExists(profileScreen.statsCard, "Stats card should be visible")

        print("✅ Profile screen loaded successfully")
    }

    func testProfileDisplaysUsername() {
        profileScreen.navigate()

        let username = profileScreen.getUsername()

        if username.isEmpty {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Username not displayed on profile",
                expectedBehavior: "Profile should display user's username",
                actualBehavior: "Username label is empty",
                stepsToReproduce: [
                    "Launch app",
                    "Navigate to Profile",
                    "Check username display"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Username displayed: \(username)")
    }

    func testProfileDisplaysStats() {
        profileScreen.navigate()

        assertElementExists(profileScreen.netWorthLabel, "Net worth should be displayed")
        assertElementExists(profileScreen.rankLabel, "Rank should be displayed")

        let netWorth = profileScreen.getNetWorth()
        let rank = profileScreen.getRank()

        print("✅ Stats displayed - Net Worth: \(netWorth), Rank: \(rank)")
    }

    // MARK: - Reset Portfolio Tests

    func testResetPortfolioSuccess() {
        profileScreen.navigate()

        let initialNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("💰 Net worth before reset: $\(initialNetWorth)")

        let success = profileScreen.resetPortfolio()

        if !success {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .functionality,
                description: "Reset portfolio operation failed",
                expectedBehavior: "Reset should complete successfully and return to starting balance",
                actualBehavior: "Reset operation failed or alert did not appear",
                stepsToReproduce: [
                    "Navigate to Profile",
                    "Tap Reset Portfolio",
                    "Confirm reset"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Reset portfolio failed")
            return
        }

        // Wait for reset to complete
        sleep(2)

        let newNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("💰 Net worth after reset: $\(newNetWorth)")

        // Verify it reset to starting balance (typically $1000)
        let expectedStartingBalance = 1000.0
        if abs(newNetWorth - expectedStartingBalance) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Reset portfolio did not return to starting balance",
                expectedBehavior: "After reset, net worth should be $\(expectedStartingBalance)",
                actualBehavior: "Net worth is $\(newNetWorth)",
                stepsToReproduce: [
                    "Navigate to Profile",
                    "Reset portfolio",
                    "Check net worth"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Expected": String(format: "%.2f", expectedStartingBalance),
                    "Actual": String(format: "%.2f", newNetWorth)
                ]
            )
        }

        print("✅ Portfolio reset successfully to $\(newNetWorth)")
    }

    func testResetPortfolioClearsHoldings() {
        // Buy some coins first
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        // Reset portfolio
        profileScreen.navigate()
        let success = profileScreen.resetPortfolio()

        if !success {
            XCTFail("Reset failed")
            return
        }

        sleep(2)

        // Navigate to portfolio and verify no holdings
        navigateToTab(.portfolio)
        sleep(1)

        let portfolioScreen = PortfolioScreen(app: app)

        if portfolioScreen.hasHoldings() {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Holdings still visible after reset",
                expectedBehavior: "Reset should clear all holdings",
                actualBehavior: "Portfolio still shows holdings after reset",
                stepsToReproduce: [
                    "Buy coins",
                    "Navigate to Profile",
                    "Reset portfolio",
                    "Check Portfolio screen",
                    "Should show no holdings"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Reset cleared all holdings")
    }

    func testCancelResetPortfolio() {
        profileScreen.navigate()

        let initialNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0

        profileScreen.tapResetPortfolio()

        guard profileScreen.isResetAlertVisible() else {
            XCTFail("Reset alert did not appear")
            return
        }

        profileScreen.cancelReset()
        sleep(1)

        let newNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0

        if newNetWorth != initialNetWorth {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Net worth changed after canceling reset",
                expectedBehavior: "Canceling reset should not change net worth",
                actualBehavior: "Net worth changed from $\(initialNetWorth) to $\(newNetWorth)",
                stepsToReproduce: [
                    "Navigate to Profile",
                    "Tap Reset Portfolio",
                    "Tap Cancel",
                    "Check net worth"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial": String(format: "%.2f", initialNetWorth),
                    "After Cancel": String(format: "%.2f", newNetWorth)
                ]
            )
        }

        print("✅ Cancel reset works correctly")
    }

    // MARK: - Settings Tests

    func testThemeToggle() {
        profileScreen.navigate()

        let initialState = profileScreen.isThemeToggleOn()

        profileScreen.toggleTheme()
        sleep(1)

        let newState = profileScreen.isThemeToggleOn()

        if initialState == newState {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .functionality,
                description: "Theme toggle did not change state",
                expectedBehavior: "Tapping theme toggle should change its state",
                actualBehavior: "Toggle state did not change",
                stepsToReproduce: [
                    "Navigate to Profile",
                    "Tap theme toggle",
                    "Check if state changed"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Theme toggle works - Changed from \(initialState) to \(newState)")
    }

    // MARK: - Rank Display Tests

    func testRankDisplay() {
        profileScreen.navigate()

        let rank = profileScreen.getRank()

        if rank.isEmpty {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Rank not displayed on profile",
                expectedBehavior: "Profile should display user's leaderboard rank",
                actualBehavior: "Rank label is empty",
                stepsToReproduce: [
                    "Navigate to Profile",
                    "Check rank display"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Rank displayed: \(rank)")
    }

    // MARK: - Net Worth Sync Tests

    func testProfileNetWorthSyncsAfterBuy() {
        // Get initial profile net worth
        profileScreen.navigate()
        let initialProfileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0

        // Buy a coin
        navigateToTab(.home)
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0

        // Check profile again
        profileScreen.navigate()
        sleep(1)

        let newProfileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0

        if abs(newProfileNetWorth - homeNetWorth) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Profile net worth did not sync after buy",
                expectedBehavior: "Profile net worth should match Home net worth",
                actualBehavior: "Home: $\(homeNetWorth), Profile: $\(newProfileNetWorth)",
                stepsToReproduce: [
                    "Check Profile net worth",
                    "Buy coin on Home",
                    "Check Profile net worth again",
                    "Should match Home"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial Profile": String(format: "%.2f", initialProfileNetWorth),
                    "Home After Buy": String(format: "%.2f", homeNetWorth),
                    "Profile After Buy": String(format: "%.2f", newProfileNetWorth)
                ]
            )
        }

        print("✅ Profile net worth synced correctly after buy")
    }
}
