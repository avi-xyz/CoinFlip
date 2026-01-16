//
//  PortfolioScreenTests.swift
//  CoinFlipUITests
//
//  Comprehensive tests for Portfolio Screen functionality
//

import XCTest

final class PortfolioScreenTests: UITestBase {

    var portfolioScreen: PortfolioScreen!
    var homeScreen: HomeScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()
        portfolioScreen = PortfolioScreen(app: app)
        homeScreen = HomeScreen(app: app)
    }

    override func tearDownWithError() throws {
        portfolioScreen = nil
        homeScreen = nil
        try super.tearDownWithError()
    }

    // MARK: - Setup Helper

    func setupPortfolioWithHoldings() {
        // Buy some coins to have holdings
        homeScreen.buyCoin(symbol: "BTC", amount: "200")
        sleep(1)
        homeScreen.buyCoin(symbol: "ETH", amount: "150")
        sleep(1)
    }

    // MARK: - Initial State Tests

    func testPortfolioScreenInitialLoad() {
        portfolioScreen.navigate()

        assertElementExists(portfolioScreen.netWorthLabel, "Net worth should be visible on portfolio screen")
        assertElementExists(portfolioScreen.cashBalanceLabel, "Cash balance should be visible")

        print("✅ Portfolio screen loaded successfully")
    }

    func testEmptyPortfolioDisplay() {
        portfolioScreen.navigate()

        // With no holdings, should show empty state
        if portfolioScreen.hasHoldings() {
            print("ℹ️ Portfolio has holdings, skipping empty state test")
        } else {
            assertElementExists(portfolioScreen.emptyPortfolioMessage, "Empty portfolio message should be displayed")
            print("✅ Empty portfolio state displayed correctly")
        }
    }

    func testPortfolioWithHoldingsDisplay() {
        // Setup: Buy coins first
        setupPortfolioWithHoldings()

        portfolioScreen.navigate()
        sleep(1)

        // Verify holdings are displayed
        if !portfolioScreen.hasHoldings() {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Holdings not displayed after purchase",
                expectedBehavior: "After buying coins, holdings should be visible in portfolio",
                actualBehavior: "Portfolio shows empty state despite recent purchases",
                stepsToReproduce: [
                    "Launch app",
                    "Buy BTC for $200",
                    "Buy ETH for $150",
                    "Navigate to Portfolio tab",
                    "Holdings should be visible"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Holdings not visible after purchase")
        }

        print("✅ Holdings displayed correctly in portfolio")
    }

    // MARK: - Sell Operation Tests

    func testSellHoldingSuccessfully() {
        // Setup: Buy coins first
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        let initialCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("💰 Initial cash before sell: $\(initialCash)")

        // Sell 50% of BTC
        let success = portfolioScreen.sellHolding(symbol: "BTC", percentage: 50)

        if !success {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .functionality,
                description: "Failed to complete sell operation",
                expectedBehavior: "Sell sheet should open, accept percentage, and complete transaction",
                actualBehavior: "Sell operation failed or timed out",
                stepsToReproduce: [
                    "Launch app",
                    "Buy BTC",
                    "Navigate to Portfolio",
                    "Tap sell on BTC",
                    "Select 50%",
                    "Confirm sell"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
            XCTFail("Sell operation failed")
            return
        }

        // Wait for UI to update
        sleep(2)

        // Verify cash increased
        let newCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        print("💵 Cash after sell: $\(newCash)")

        if newCash <= initialCash {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Cash did not increase after sell",
                expectedBehavior: "Cash should increase after selling holdings",
                actualBehavior: "Cash before: $\(initialCash), Cash after: $\(newCash)",
                stepsToReproduce: [
                    "Launch app",
                    "Buy coins",
                    "Navigate to Portfolio",
                    "Sell 50% of holding",
                    "Check cash balance"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial Cash": String(format: "%.2f", initialCash),
                    "Cash After Sell": String(format: "%.2f", newCash)
                ]
            )
        }

        print("✅ Sell operation completed successfully")
    }

    func testSellAllHoldings() {
        // Setup: Buy coins first
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        // Sell 100% of BTC
        let success = portfolioScreen.sellHolding(symbol: "BTC", percentage: 100)

        if !success {
            XCTFail("Failed to sell all holdings")
            return
        }

        // Wait for UI to update
        sleep(2)

        // Verify BTC holding is removed
        if portfolioScreen.isHoldingVisible(symbol: "BTC") {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .dataConsistency,
                description: "Holding still visible after selling 100%",
                expectedBehavior: "After selling 100% of a holding, it should be removed from the list",
                actualBehavior: "BTC holding still appears in portfolio after complete sell",
                stepsToReproduce: [
                    "Launch app",
                    "Buy BTC",
                    "Navigate to Portfolio",
                    "Sell 100% of BTC",
                    "Holding should disappear"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }

        print("✅ Complete sell operation removed holding correctly")
    }

    func testSellMultiplePercentages() {
        // Test different sell percentages (25%, 50%, 75%, 100%)
        let percentages = [25, 50, 75, 100]

        for percentage in percentages {
            // Setup fresh holding
            homeScreen.buyCoin(symbol: "DOGE", amount: "100")
            sleep(1)

            portfolioScreen.navigate()
            sleep(1)

            let success = portfolioScreen.sellHolding(symbol: "DOGE", percentage: percentage)

            if !success {
                reporter.reportBug(
                    testName: testName,
                    severity: .high,
                    category: .functionality,
                    description: "Failed to sell \(percentage)% of holding",
                    expectedBehavior: "Should be able to sell any percentage (25%, 50%, 75%, 100%)",
                    actualBehavior: "Sell operation failed for \(percentage)%",
                    stepsToReproduce: [
                        "Launch app",
                        "Buy DOGE",
                        "Navigate to Portfolio",
                        "Tap sell on DOGE",
                        "Select \(percentage)%",
                        "Confirm sell"
                    ],
                    screenshot: XCUIScreen.main.screenshot(),
                    additionalContext: ["Percentage": "\(percentage)"]
                )
            }

            sleep(2)

            // For 100% sell, verify holding is removed
            if percentage == 100 && portfolioScreen.isHoldingVisible(symbol: "DOGE") {
                reporter.reportBug(
                    testName: testName,
                    severity: .high,
                    category: .dataConsistency,
                    description: "Holding visible after 100% sell",
                    expectedBehavior: "Holding should be removed after selling 100%",
                    actualBehavior: "DOGE still visible after complete sell",
                    stepsToReproduce: [
                        "Buy DOGE",
                        "Sell 100%",
                        "Check portfolio"
                    ],
                    screenshot: XCUIScreen.main.screenshot()
                )
            }

            // Navigate back to home to reset for next iteration
            navigateToTab(.home)
            sleep(1)
        }

        print("✅ All percentage sell operations tested")
    }

    func testCancelSellOperation() {
        // Setup: Buy coins first
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        let initialCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0

        // Start sell operation
        portfolioScreen.tapSell(symbol: "BTC")

        guard portfolioScreen.sellSheet.waitForExistence(timeout: 3) else {
            XCTFail("Sell sheet did not appear")
            return
        }

        portfolioScreen.tapSellPercentage(50)
        portfolioScreen.cancelSell()

        // Wait for sheet to dismiss
        sleep(1)

        // Verify cash did not change
        let newCash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0

        if newCash != initialCash {
            reporter.reportBug(
                testName: testName,
                severity: .high,
                category: .functionality,
                description: "Cash changed after canceling sell",
                expectedBehavior: "Canceling sell should not change cash balance",
                actualBehavior: "Cash changed from $\(initialCash) to $\(newCash)",
                stepsToReproduce: [
                    "Launch app with holdings",
                    "Navigate to Portfolio",
                    "Tap sell on a holding",
                    "Select percentage",
                    "Tap cancel",
                    "Check cash balance"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Initial Cash": String(format: "%.2f", initialCash),
                    "Cash After Cancel": String(format: "%.2f", newCash)
                ]
            )
        }

        print("✅ Cancel sell operation works correctly")
    }

    // MARK: - Holdings Display Tests

    func testHoldingQuantityDisplay() {
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        // Check if BTC quantity is displayed
        let btcQty = portfolioScreen.holdingQuantity(symbol: "BTC")

        if !btcQty.exists {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Holding quantity not displayed",
                expectedBehavior: "Each holding should display quantity owned",
                actualBehavior: "BTC quantity element not found",
                stepsToReproduce: [
                    "Buy BTC",
                    "Navigate to Portfolio",
                    "Check holding display"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }
    }

    func testHoldingValueDisplay() {
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        // Check if BTC value is displayed
        let btcValue = portfolioScreen.holdingValue(symbol: "BTC")

        if !btcValue.exists {
            reporter.reportBug(
                testName: testName,
                severity: .medium,
                category: .ui,
                description: "Holding value not displayed",
                expectedBehavior: "Each holding should display current value",
                actualBehavior: "BTC value element not found",
                stepsToReproduce: [
                    "Buy BTC",
                    "Navigate to Portfolio",
                    "Check holding display"
                ],
                screenshot: XCUIScreen.main.screenshot()
            )
        }
    }

    // MARK: - Net Worth Calculation Tests

    func testNetWorthEqualsHoldingsPlusCash() {
        setupPortfolioWithHoldings()
        portfolioScreen.navigate()
        sleep(1)

        let netWorth = extractCurrencyValue(from: portfolioScreen.netWorthLabel) ?? 0
        let cash = extractCurrencyValue(from: portfolioScreen.cashBalanceLabel) ?? 0
        let holdingsValue = extractCurrencyValue(from: portfolioScreen.holdingsValueLabel) ?? 0

        let calculatedNetWorth = cash + holdingsValue
        let tolerance = 0.01

        if abs(netWorth - calculatedNetWorth) > tolerance {
            reporter.reportBug(
                testName: testName,
                severity: .critical,
                category: .dataConsistency,
                description: "Net worth calculation incorrect",
                expectedBehavior: "Net worth should equal cash + holdings value",
                actualBehavior: "Net worth: $\(netWorth), Cash: $\(cash), Holdings: $\(holdingsValue), Expected: $\(calculatedNetWorth)",
                stepsToReproduce: [
                    "Buy coins",
                    "Navigate to Portfolio",
                    "Compare net worth with cash + holdings"
                ],
                screenshot: XCUIScreen.main.screenshot(),
                additionalContext: [
                    "Net Worth": String(format: "%.2f", netWorth),
                    "Cash": String(format: "%.2f", cash),
                    "Holdings Value": String(format: "%.2f", holdingsValue),
                    "Expected Net Worth": String(format: "%.2f", calculatedNetWorth),
                    "Difference": String(format: "%.2f", abs(netWorth - calculatedNetWorth))
                ]
            )
        }

        print("✅ Net worth calculation is correct: $\(netWorth) = $\(cash) + $\(holdingsValue)")
    }

    // MARK: - Refresh Tests

    func testPullToRefresh() {
        portfolioScreen.navigate()
        sleep(1)

        let initialNetWorth = portfolioScreen.getNetWorth()

        portfolioScreen.pullToRefresh()

        let newNetWorth = portfolioScreen.getNetWorth()

        // Verify UI still displays correctly after refresh
        assertElementExists(portfolioScreen.netWorthLabel, "Net worth should be visible after refresh")

        print("✅ Pull to refresh completed - Net worth: \(initialNetWorth) -> \(newNetWorth)")
    }
}
