//
//  EndToEndWorkflowTests.swift
//  CoinFlipUITests
//
//  End-to-end workflow tests simulating real user scenarios
//

import XCTest

final class EndToEndWorkflowTests: UITestBase {

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

    // MARK: - Complete User Journey Tests

    func testCompleteUserJourney_ResetBuySell() {
        // This test simulates the exact scenario the user reported:
        // 1. Reset portfolio
        // 2. Buy multiple coins
        // 3. Sell all coins
        // 4. Verify consistency across all screens

        print("\n🎬 STARTING COMPLETE USER JOURNEY TEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Scenario: Reset → Buy BTC, ETH, DOGE, XMR → Sell All → Verify Consistency")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Step 1: Reset Portfolio
        print("\n📍 STEP 1: Reset Portfolio")
        profileScreen.navigate()
        sleep(1)

        let resetSuccess = profileScreen.resetPortfolio()
        if !resetSuccess {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .functionality,
                description: "Failed to reset portfolio",
                expectedBehavior: "Reset portfolio should complete successfully",
                actualBehavior: "Reset operation failed or timed out",
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

        sleep(2)

        // Verify reset state
        let resetNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("   ✓ Portfolio reset complete, Net Worth: $\(resetNetWorth)")

        // Step 2: Buy Multiple Coins
        print("\n📍 STEP 2: Buy Multiple Coins")
        navigateToTab(.home)
        sleep(1)

        let purchases = [
            ("BTC", "400"),
            ("ETH", "184"),
            ("DOGE", "172"),
            ("XMR", "244")
        ]

        var purchaseSuccess = true
        for (symbol, amount) in purchases {
            print("   🛒 Buying \(symbol) for $\(amount)...")
            let success = homeScreen.buyCoin(symbol: symbol, amount: amount)
            if !success {
                reporter.reportBug(
                    testName: testName,
                    severity: .critical,
                    category: .functionality,
                    description: "Failed to buy \(symbol)",
                    expectedBehavior: "Should be able to buy \(symbol) for $\(amount)",
                    actualBehavior: "Buy operation failed",
                    stepsToReproduce: [
                        "Reset portfolio",
                        "Buy \(symbol) for $\(amount)"
                    ],
                    screenshot: XCUIScreen.main.screenshot(),
                    additionalContext: ["Coin": symbol, "Amount": amount]
                )
                purchaseSuccess = false
                break
            }
            sleep(2) // Wait between purchases
        }

        if !purchaseSuccess {
            XCTFail("Not all purchases completed successfully")
            return
        }

        print("   ✓ All purchases completed")

        // Verify portfolio has holdings
        portfolioScreen.navigate()
        sleep(2)

        if !portfolioScreen.hasHoldings() {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "No holdings visible after purchases",
                expectedBehavior: "Portfolio should show 4 holdings after buying 4 coins",
                actualBehavior: "Portfolio shows empty state",
                stepsToReproduce: [
                    "Reset portfolio",
                    "Buy BTC, ETH, DOGE, XMR",
                    "Navigate to Portfolio",
                    "Check holdings"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("No holdings after purchase")
            return
        }

        let afterBuyNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        print("   ✓ Holdings visible in portfolio, Net Worth: $\(afterBuyNetWorth)")

        // Step 3: Sell All Coins
        print("\n📍 STEP 3: Sell All Coins")

        for (symbol, _) in purchases {
            if portfolioScreen.isHoldingVisible(symbol: symbol) {
                print("   💰 Selling all \(symbol)...")
                let success = portfolioScreen.sellHolding(symbol: symbol, percentage: 100)
                if !success {
                    reporter.reportBug(
                        testName: testName,
                        severity: .critical,
                        category: .functionality,
                        description: "Failed to sell \(symbol)",
                        expectedBehavior: "Should be able to sell 100% of \(symbol)",
                        actualBehavior: "Sell operation failed",
                        stepsToReproduce: [
                            "Buy coins",
                            "Navigate to Portfolio",
                            "Sell 100% of \(symbol)"
                        ],
                        screenshot: XCUIScreen.main.screenshot(),
                        additionalContext: ["Coin": symbol]
                    )
                }
                sleep(2) // Wait between sells
            }
        }

        print("   ✓ All coins sold")

        // Wait for UI to settle
        sleep(2)

        // Step 4: Verify Final State - Pull to Refresh
        print("\n📍 STEP 4: Pull to Refresh and Verify Final State")

        portfolioScreen.pullToRefresh()
        sleep(2)

        let finalPortfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        let finalPortfolioCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("   💼 Portfolio: Net Worth=$\(finalPortfolioNetWorth), Cash=$\(finalPortfolioCash)")

        navigateToTab(.home)
        sleep(1)
        homeScreen.pullToRefresh()
        sleep(2)

        let finalHomeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0
        let finalHomeCash = extractCurrencyValue(from: homeScreen.cashBalanceLabel) ?? 0
        print("   🏠 Home: Net Worth=$\(finalHomeNetWorth), Cash=$\(finalHomeCash)")

        leaderboardScreen.navigate()
        sleep(1)
        leaderboardScreen.pullToRefresh()
        sleep(2)

        let finalLeaderboardNetWorth = extractCurrencyValue(from: leaderboardScreen.currentUserNetWorth) ?? 0
        print("   🏆 Leaderboard: Net Worth=$\(finalLeaderboardNetWorth)")

        profileScreen.navigate()
        sleep(1)

        let finalProfileNetWorth = extractCurrencyValue(from: profileScreen.netWorthLabel) ?? 0
        print("   👤 Profile: Net Worth=$\(finalProfileNetWorth)")

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 FINAL VERIFICATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Step 5: Verify consistency across all screens
        print("\n📍 STEP 5: Verify Consistency Across All Screens")

        let tolerance = 0.01
        let allNetWorths = [finalHomeNetWorth, finalPortfolioNetWorth, finalLeaderboardNetWorth, finalProfileNetWorth]
        let maxNetWorth = allNetWorths.max() ?? 0
        let minNetWorth = allNetWorths.min() ?? 0
        let difference = maxNetWorth - minNetWorth

        print("   Max Net Worth: $\(maxNetWorth)")
        print("   Min Net Worth: $\(minNetWorth)")
        print("   Difference: $\(difference)")

        if difference > tolerance {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "❌ NET WORTH INCONSISTENCY after complete buy/sell cycle",
                expectedBehavior: "After reset → buy → sell → refresh cycle, net worth should be consistent across all screens",
                actualBehavior: "Net worth differs by $\(String(format: "%.2f", difference)) across screens",
                stepsToReproduce: [
                    "Reset portfolio to starting balance",
                    "Buy BTC ($400), ETH ($184), DOGE ($172), XMR ($244)",
                    "Sell all 4 coins at 100%",
                    "Pull to refresh on all screens",
                    "Check net worth on Home, Portfolio, Leaderboard, Profile"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial Net Worth": String(format: "%.2f", resetNetWorth),
                    "Home Net Worth": String(format: "%.2f", finalHomeNetWorth),
                    "Portfolio Net Worth": String(format: "%.2f", finalPortfolioNetWorth),
                    "Leaderboard Net Worth": String(format: "%.2f", finalLeaderboardNetWorth),
                    "Profile Net Worth": String(format: "%.2f", finalProfileNetWorth),
                    "Max Value": String(format: "%.2f", maxNetWorth),
                    "Min Value": String(format: "%.2f", minNetWorth),
                    "Difference": String(format: "%.2f", difference)
                ]
            )

            print("\n❌ TEST FAILED: Net Worth Inconsistency Detected")
            print("   Home: $\(finalHomeNetWorth)")
            print("   Portfolio: $\(finalPortfolioNetWorth)")
            print("   Leaderboard: $\(finalLeaderboardNetWorth)")
            print("   Profile: $\(finalProfileNetWorth)")

            XCTFail("Net worth inconsistency detected: difference of $\(difference)")
        } else {
            print("\n✅ TEST PASSED: Net Worth is Consistent Across All Screens")
            print("   All screens show: $\(finalHomeNetWorth)")
        }

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎬 COMPLETE USER JOURNEY TEST FINISHED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    func testBuyAndHoldMultipleCoins() {
        print("\n🎬 TESTING: Buy and Hold Multiple Coins")

        // Buy 3 different coins and keep them
        homeScreen.buyCoin(symbol: "BTC", amount: "300")
        sleep(2)
        homeScreen.buyCoin(symbol: "ETH", amount: "200")
        sleep(2)
        homeScreen.buyCoin(symbol: "DOGE", amount: "100")
        sleep(2)

        // Check portfolio
        portfolioScreen.navigate()
        sleep(1)

        let holdingCount = portfolioScreen.getHoldingCount()
        if holdingCount < 3 {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .dataConsistency,
                description: "Not all holdings visible in portfolio",
                expectedBehavior: "Portfolio should show 3 holdings",
                actualBehavior: "Only \(holdingCount) holdings visible",
                stepsToReproduce: [
                    "Buy BTC, ETH, DOGE",
                    "Navigate to Portfolio",
                    "Count visible holdings"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: ["Expected Holdings": "3", "Actual Holdings": "\(holdingCount)"]
            )
        }

        // Verify net worth consistency
        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0

        navigateToTab(.home)
        sleep(1)
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0

        if abs(portfolioNetWorth - homeNetWorth) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Net worth inconsistency with multiple holdings",
                expectedBehavior: "Net worth should match across screens",
                actualBehavior: "Home: $\(homeNetWorth), Portfolio: $\(portfolioNetWorth)",
                stepsToReproduce: [
                    "Buy multiple coins",
                    "Check net worth on Home and Portfolio"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Home": String(format: "%.2f", homeNetWorth),
                    "Portfolio": String(format: "%.2f", portfolioNetWorth)
                ]
            )
        }

        print("✅ Buy and hold test completed")
    }

    func testPartialSellsWorkflow() {
        print("\n🎬 TESTING: Partial Sells Workflow")

        // Buy and progressively sell
        homeScreen.buyCoin(symbol: "BTC", amount: "400")
        sleep(2)

        portfolioScreen.navigate()
        sleep(1)

        // Sell 25%
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 25)
        sleep(2)

        // Sell another 25% (50% total)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 25)
        sleep(2)

        // Sell another 25% (75% total)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 25)
        sleep(2)

        // Sell final 25% (100% total)
        portfolioScreen.sellHolding(symbol: "BTC", percentage: 25)
        sleep(2)

        // Verify BTC is removed after selling all
        if portfolioScreen.isHoldingVisible(symbol: "BTC") {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .dataConsistency,
                description: "Holding visible after selling all via partial sells",
                expectedBehavior: "After selling 4 x 25%, holding should be removed",
                actualBehavior: "BTC still visible in portfolio",
                stepsToReproduce: [
                    "Buy BTC",
                    "Sell 25%",
                    "Sell 25%",
                    "Sell 25%",
                    "Sell 25%",
                    "Check if holding is removed"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Partial sells workflow completed")
    }

    func testRapidBuySellCycle() {
        print("\n🎬 TESTING: Rapid Buy/Sell Cycle")

        // Rapidly buy and sell the same coin multiple times
        for _ in 1...3 {
            homeScreen.buyCoin(symbol: "ETH", amount: "100")
            sleep(1)

            portfolioScreen.navigate()
            sleep(1)

            portfolioScreen.sellHolding(symbol: "ETH", percentage: 100)
            sleep(1)

            navigateToTab(.home)
            sleep(1)
        }

        // Verify final state consistency
        let homeNetWorth = extractCurrencyValue(from: homeScreen.netWorthLabel) ?? 0

        portfolioScreen.navigate()
        sleep(1)
        let portfolioNetWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0

        if abs(homeNetWorth - portfolioNetWorth) > 0.01 {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Net worth inconsistency after rapid buy/sell cycles",
                expectedBehavior: "Net worth should remain consistent",
                actualBehavior: "Home: $\(homeNetWorth), Portfolio: $\(portfolioNetWorth)",
                stepsToReproduce: [
                    "Perform 3 rapid buy/sell cycles",
                    "Check net worth consistency"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Home": String(format: "%.2f", homeNetWorth),
                    "Portfolio": String(format: "%.2f", portfolioNetWorth)
                ]
            )
        }

        print("✅ Rapid buy/sell cycle completed")
    }
}
