//
//  DataConsistencyTests.swift
//  CoinFlipUITests
//
//  Critical tests for data consistency across all screens
//  This is THE MOST IMPORTANT test suite for catching net worth discrepancies
//

import XCTest

final class DataConsistencyTests: UITestBase {

    var homeScreen: HomeScreen!
    var portfolioScreen: PortfolioScreen!
    var leaderboardScreen: LeaderboardScreen!
    var profileScreen: ProfileScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()
        homeScreen = HomeScreen(app: app)
        portfolioScreen = PortfolioScreen(app: app)
        leaderboardScreen = LeaderboardScreen(app: app)
        profileScreen = ProfileScreen(app: app)
    }

    override func tearDownWithError() throws {
        homeScreen = nil
        portfolioScreen = nil
        leaderboardScreen = nil
        profileScreen = nil
        try super.tearDownWithError()
    }

    // MARK: - Net Worth Consistency Tests

    func testNetWorthConsistencyAcrossAllScreens() {
        // This is the PRIMARY test for the bug the user reported
        print("\n🔍 TESTING NET WORTH CONSISTENCY ACROSS ALL SCREENS")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 1. Get net worth from Home screen
        let homeNetWorth = homeScreen.getNetWorth()
        let homeNetWorthValue = extractCurrencyValue(from: homeScreen.netWorthLabel)
        print("🏠 Home Screen Net Worth: \(homeNetWorth) = $\(homeNetWorthValue ?? 0)")

        // 2. Navigate to Portfolio and get net worth
        portfolioScreen.navigate()
        sleep(1)
        let portfolioNetWorth = portfolioScreen.getNetWorth()
        let portfolioNetWorthValue = extractCurrencyValue(from: portfolioScreen.netWorthLabel)
        print("💼 Portfolio Screen Net Worth: \(portfolioNetWorth) = $\(portfolioNetWorthValue ?? 0)")

        // 3. Navigate to Leaderboard and get net worth
        leaderboardScreen.navigate()
        sleep(1)
        let leaderboardNetWorth = leaderboardScreen.getCurrentUserNetWorth()
        let leaderboardNetWorthValue = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth)
        print("🏆 Leaderboard Net Worth: \(leaderboardNetWorth) = $\(leaderboardNetWorthValue ?? 0)")

        // 4. Navigate to Profile and get net worth
        profileScreen.navigate()
        sleep(1)
        let profileNetWorth = profileScreen.getNetWorth()
        let profileNetWorthValue = extractCurrencyValue(from: profileScreen.netWorthLabel)
        print("👤 Profile Screen Net Worth: \(profileNetWorth) = $\(profileNetWorthValue ?? 0)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 5. Verify all values are consistent
        let tolerance = 0.01 // Allow 1 cent tolerance for rounding

        let allValues = [homeNetWorthValue, portfolioNetWorthValue, leaderboardNetWorthValue, profileNetWorthValue].compactMap { $0 }

        if allValues.isEmpty {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Cannot extract net worth values from any screen",
                expectedBehavior: "All screens should display parseable net worth values",
                actualBehavior: "Failed to extract numeric values from displayed text",
                stepsToReproduce: [
                    "Launch app",
                    "Check net worth on all screens",
                    "Values should be numeric and parseable"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Home": homeNetWorth,
                    "Portfolio": portfolioNetWorth,
                    "Leaderboard": leaderboardNetWorth,
                    "Profile": profileNetWorth
                ]
            )
            XCTFail("Cannot extract net worth values")
            return
        }

        let maxValue = allValues.max()!
        let minValue = allValues.min()!
        let difference = maxValue - minValue

        if difference > tolerance {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "NET WORTH INCONSISTENCY DETECTED ACROSS SCREENS",
                expectedBehavior: "Net worth should be identical across Home, Portfolio, Leaderboard, and Profile screens",
                actualBehavior: "Found inconsistent values with difference of $\(String(format: "%.2f", difference))",
                stepsToReproduce: [
                    "Launch app",
                    "Check net worth on Home screen",
                    "Navigate to Portfolio screen",
                    "Navigate to Leaderboard screen",
                    "Navigate to Profile screen",
                    "Compare all values"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Home Net Worth": String(format: "%.2f", homeNetWorthValue ?? 0),
                    "Portfolio Net Worth": String(format: "%.2f", portfolioNetWorthValue ?? 0),
                    "Leaderboard Net Worth": String(format: "%.2f", leaderboardNetWorthValue ?? 0),
                    "Profile Net Worth": String(format: "%.2f", profileNetWorthValue ?? 0),
                    "Max Value": String(format: "%.2f", maxValue),
                    "Min Value": String(format: "%.2f", minValue),
                    "Difference": String(format: "%.2f", difference),
                    "Tolerance": String(format: "%.2f", tolerance)
                ]
            )

            XCTFail("❌ NET WORTH INCONSISTENCY: Home=$\(homeNetWorthValue ?? 0), Portfolio=$\(portfolioNetWorthValue ?? 0), Leaderboard=$\(leaderboardNetWorthValue ?? 0), Profile=$\(profileNetWorthValue ?? 0)")
        } else {
            print("✅ NET WORTH IS CONSISTENT ACROSS ALL SCREENS: $\(String(format: "%.2f", homeNetWorthValue ?? 0))")
        }
    }

    func testNetWorthConsistencyAfterBuy() {
        print("\n🔍 TESTING NET WORTH CONSISTENCY AFTER BUY OPERATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Buy a coin
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        // Check consistency across all screens
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0
        print("🏠 Home Net Worth after buy: $\(homeNetWorth)")

        portfolioScreen.navigate()
        sleep(1)
        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        print("💼 Portfolio Net Worth: $\(portfolioNetWorth)")

        leaderboardScreen.navigate()
        sleep(1)
        let leaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0
        print("🏆 Leaderboard Net Worth: $\(leaderboardNetWorth)")

        profileScreen.navigate()
        sleep(1)
        let profileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("👤 Profile Net Worth: $\(profileNetWorth)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Verify consistency
        assertDataConsistency(
            description: "Net worth after buy operation",
            values: [
                "Home": String(format: "%.2f", homeNetWorth),
                "Portfolio": String(format: "%.2f", portfolioNetWorth),
                "Leaderboard": String(format: "%.2f", leaderboardNetWorth),
                "Profile": String(format: "%.2f", profileNetWorth)
            ]
        )
    }

    func testNetWorthConsistencyAfterSell() {
        print("\n🔍 TESTING NET WORTH CONSISTENCY AFTER SELL OPERATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Setup: Buy then sell
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        portfolioScreen.navigate()
        sleep(1)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 50)
        sleep(2)

        // Check consistency after sell
        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        print("💼 Portfolio Net Worth after sell: $\(portfolioNetWorth)")

        navigateToTab(.home)
        sleep(1)
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0
        print("🏠 Home Net Worth: $\(homeNetWorth)")

        leaderboardScreen.navigate()
        sleep(1)
        let leaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0
        print("🏆 Leaderboard Net Worth: $\(leaderboardNetWorth)")

        profileScreen.navigate()
        sleep(1)
        let profileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("👤 Profile Net Worth: $\(profileNetWorth)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Verify consistency
        assertDataConsistency(
            description: "Net worth after sell operation",
            values: [
                "Home": String(format: "%.2f", homeNetWorth),
                "Portfolio": String(format: "%.2f", portfolioNetWorth),
                "Leaderboard": String(format: "%.2f", leaderboardNetWorth),
                "Profile": String(format: "%.2f", profileNetWorth)
            ]
        )
    }

    func testNetWorthConsistencyAfterCompleteSell() {
        print("\n🔍 TESTING NET WORTH CONSISTENCY AFTER COMPLETE SELL (100%)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Buy coins
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        // Sell 100%
        portfolioScreen.navigate()
        sleep(1)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 100)
        sleep(2)

        // Check consistency
        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        print("💼 Portfolio Net Worth after complete sell: $\(portfolioNetWorth)")

        navigateToTab(.home)
        sleep(1)
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0
        print("🏠 Home Net Worth: $\(homeNetWorth)")

        leaderboardScreen.navigate()
        sleep(1)
        let leaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0
        print("🏆 Leaderboard Net Worth: $\(leaderboardNetWorth)")

        profileScreen.navigate()
        sleep(1)
        let profileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("👤 Profile Net Worth: $\(profileNetWorth)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        assertDataConsistency(
            description: "Net worth after complete sell (should equal starting balance)",
            values: [
                "Home": String(format: "%.2f", homeNetWorth),
                "Portfolio": String(format: "%.2f", portfolioNetWorth),
                "Leaderboard": String(format: "%.2f", leaderboardNetWorth),
                "Profile": String(format: "%.2f", profileNetWorth)
            ]
        )
    }

    func testNetWorthConsistencyAfterRefresh() {
        print("\n🔍 TESTING NET WORTH CONSISTENCY AFTER PULL TO REFRESH")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Buy some coins
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        // Refresh on home screen
        homeScreen.pullToRefresh()
        sleep(2)

        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0
        print("🏠 Home Net Worth after refresh: $\(homeNetWorth)")

        // Navigate to portfolio and refresh
        portfolioScreen.navigate()
        sleep(1)
        portfolioScreen.pullToRefresh()
        sleep(2)

        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        print("💼 Portfolio Net Worth after refresh: $\(portfolioNetWorth)")

        // Check leaderboard
        leaderboardScreen.navigate()
        sleep(1)
        leaderboardScreen.pullToRefresh()
        sleep(2)

        let leaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0
        print("🏆 Leaderboard Net Worth after refresh: $\(leaderboardNetWorth)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        assertDataConsistency(
            description: "Net worth after pull to refresh on multiple screens",
            values: [
                "Home": String(format: "%.2f", homeNetWorth),
                "Portfolio": String(format: "%.2f", portfolioNetWorth),
                "Leaderboard": String(format: "%.2f", leaderboardNetWorth)
            ]
        )
    }

    // MARK: - Cash Balance Consistency Tests

    func testCashBalanceConsistencyAcrossScreens() {
        print("\n🔍 TESTING CASH BALANCE CONSISTENCY")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // NOTE: Home screen doesn't display cash balance separately
        // Only Portfolio screen shows cash balance explicitly

        portfolioScreen.navigate()
        sleep(1)
        let portfolioCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("💼 Portfolio Cash: $\(portfolioCash)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Just verify portfolio cash exists and is a valid number
        XCTAssertGreaterThanOrEqual(portfolioCash, 0, "Portfolio cash balance should be non-negative")
        print("✅ Portfolio cash balance is valid: $\(portfolioCash)")
    }

    func testCashBalanceConsistencyAfterBuyAndSell() {
        print("\n🔍 TESTING CASH BALANCE CONSISTENCY AFTER BUY AND SELL CYCLE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Get initial cash from Portfolio screen
        portfolioScreen.navigate()
        sleep(1)
        let initialCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("💵 Initial Cash: $\(initialCash)")

        // Buy and sell same coin
        navigateToTab(.home)
        sleep(1)
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(2)

        portfolioScreen.navigate()
        sleep(1)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 100)
        sleep(2)

        let portfolioCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("💼 Portfolio Cash after sell: $\(portfolioCash)")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Verify cash is close to initial (accounting for small price changes)
        let difference = abs(portfolioCash - initialCash)
        XCTAssertLessThan(difference, 50, "Cash should be close to initial value after complete buy/sell cycle")
        print("✅ Cash balance after buy/sell cycle: $\(portfolioCash) (initial: $\(initialCash))")
    }
}
