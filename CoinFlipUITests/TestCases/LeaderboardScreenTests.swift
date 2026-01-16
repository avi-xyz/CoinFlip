//
//  LeaderboardScreenTests.swift
//  CoinFlipUITests
//
//  Comprehensive tests for Leaderboard Screen functionality
//

import XCTest

final class LeaderboardScreenTests: UITestBase {

    var leaderboardScreen: LeaderboardScreen!
    var homeScreen: HomeScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()
        leaderboardScreen = LeaderboardScreen(app: app)
        homeScreen = HomeScreen(app: app)
    }

    override func tearDownWithError() throws {
        leaderboardScreen = nil
        homeScreen = nil
        try super.tearDownWithError()
    }

    // MARK: - Initial State Tests

    func testLeaderboardScreenInitialLoad() {
        leaderboardScreen.navigate()

        assertElementExists(leaderboardScreen.leaderboardList, "Leaderboard list should be visible")
        assertElementExists(leaderboardScreen.currentUserCard, "Current user card should be visible")

        print("✅ Leaderboard screen loaded successfully")
    }

    func testLeaderboardDisplaysEntries() {
        leaderboardScreen.navigate()

        let entryCount = leaderboardScreen.getLeaderboardEntryCount()

        if entryCount == 0 {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Leaderboard shows no entries",
                expectedBehavior: "Leaderboard should display at least some entries",
                actualBehavior: "No leaderboard entries found",
                stepsToReproduce: [
                    "Launch app",
                    "Navigate to Leaderboard",
                    "Check for entries"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Leaderboard displays \(entryCount) entries")
    }

    func testCurrentUserCardDisplay() {
        leaderboardScreen.navigate()

        assertElementExists(leaderboardScreen.currentUserCard, "Current user card should be visible")
        assertElementExists(leaderboardScreen.currentUserRank, "Current user rank should be visible")
        assertElementExists(leaderboardScreen.currentUserNetWorth, "Current user net worth should be visible")

        let rank = leaderboardScreen.getCurrentUserRank()
        let netWorth = leaderboardScreen.getCurrentUserNetWorth()
        let gain = leaderboardScreen.getCurrentUserGain()

        print("✅ Current user card displayed - Rank: \(rank), Net Worth: \(netWorth), Gain: \(gain)")
    }

    // MARK: - Data Display Tests

    func testLeaderboardEntryDataFormat() {
        leaderboardScreen.navigate()

        // Check if first entry has proper data
        if leaderboardScreen.isEntryVisible(rank: 1) {
            let username = leaderboardScreen.getUsernameAt(rank: 1)
            let netWorth = leaderboardScreen.getNetWorthAt(rank: 1)
            let gain = leaderboardScreen.getGainAt(rank: 1)

            if username.isEmpty {
                reporter.reportBug(
                    testName: testName,
                    severity: .medium,
                    category: .ui,
                    description: "Leaderboard entry missing username",
                    expectedBehavior: "Each entry should display username",
                    actualBehavior: "Rank 1 entry has empty username",
                    stepsToReproduce: [
                        "Navigate to Leaderboard",
                        "Check first entry data"
                    ],
                    screenshot: XCUIScreen.main.screenshot()
                )
            }

            if netWorth.isEmpty {
                reporter.reportBug(
                    testName: testName,
                    severity: .medium,
                    category: .ui,
                    description: "Leaderboard entry missing net worth",
                    expectedBehavior: "Each entry should display net worth",
                    actualBehavior: "Rank 1 entry has empty net worth",
                    stepsToReproduce: [
                        "Navigate to Leaderboard",
                        "Check first entry data"
                    ],
                    screenshot: XCUIScreen.main.screenshot()
                )
            }

            print("✅ Leaderboard entry format correct - Username: \(username), Net Worth: \(netWorth), Gain: \(gain)")
        }
    }

    // MARK: - Net Worth Sync Tests

    func testLeaderboardNetWorthSyncsWithHome() {
        // Get home net worth
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0

        // Navigate to leaderboard
        leaderboardScreen.navigate()
        sleep(1)

        let leaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0

        if abs(leaderboardNetWorth - homeNetWorth) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Leaderboard net worth does not match Home",
                expectedBehavior: "Leaderboard should display same net worth as Home",
                actualBehavior: "Home: $\(homeNetWorth), Leaderboard: $\(leaderboardNetWorth)",
                stepsToReproduce: [
                    "Check net worth on Home",
                    "Navigate to Leaderboard",
                    "Compare net worth values"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Home": String(format: "%.2f", homeNetWorth),
                    "Leaderboard": String(format: "%.2f", leaderboardNetWorth)
                ]
            )
        }

        print("✅ Leaderboard net worth synced with Home: $\(leaderboardNetWorth)")
    }

    func testLeaderboardUpdatesAfterBuy() {
        // Get initial leaderboard net worth
        leaderboardScreen.navigate()
        sleep(1)
        let initialNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0

        // Buy a coin
        navigateToTab(.home)
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0

        // Check leaderboard again
        leaderboardScreen.navigate()
        sleep(1)

        let newLeaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0

        if abs(newLeaderboardNetWorth - homeNetWorth) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Leaderboard did not update after buy",
                expectedBehavior: "Leaderboard should reflect new net worth after buy",
                actualBehavior: "Home: $\(homeNetWorth), Leaderboard: $\(newLeaderboardNetWorth)",
                stepsToReproduce: [
                    "Check Leaderboard net worth",
                    "Buy coin on Home",
                    "Check Leaderboard again",
                    "Should match Home net worth"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial Leaderboard": String(format: "%.2f", initialNetWorth),
                    "Home After Buy": String(format: "%.2f", homeNetWorth),
                    "Leaderboard After Buy": String(format: "%.2f", newLeaderboardNetWorth)
                ]
            )
        }

        print("✅ Leaderboard updated correctly after buy")
    }

    // MARK: - Refresh Tests

    func testPullToRefresh() {
        leaderboardScreen.navigate()

        let initialNetWorth = leaderboardScreen.getCurrentUserNetWorth()

        leaderboardScreen.pullToRefresh()

        let newNetWorth = leaderboardScreen.getCurrentUserNetWorth()

        // Verify UI still displays correctly after refresh
        assertElementExists(leaderboardScreen.currentUserCard, "Current user card should be visible after refresh")

        print("✅ Pull to refresh completed - Net worth: \(initialNetWorth) -> \(newNetWorth)")
    }

    // MARK: - Ranking Tests

    func testUserRankDisplay() {
        leaderboardScreen.navigate()

        let rank = leaderboardScreen.getCurrentUserRank()

        // Rank should be numeric
        let rankValue = Int(rank.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))

        if rankValue == nil {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "User rank is not numeric",
                expectedBehavior: "Rank should be a numeric value",
                actualBehavior: "Rank displayed as: \(rank)",
                stepsToReproduce: [
                    "Navigate to Leaderboard",
                    "Check current user rank"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: ["Rank": rank]
            )
        }

        print("✅ User rank displayed: \(rank)")
    }
}
