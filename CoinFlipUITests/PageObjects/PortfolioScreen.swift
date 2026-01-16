//
//  PortfolioScreen.swift
//  CoinFlipUITests
//
//  Page Object for Portfolio Screen
//

import XCTest

class PortfolioScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var portfolioTab: XCUIElement {
        app.tabBars.buttons["Portfolio"]
    }

    var netWorthLabel: XCUIElement {
        app.staticTexts.matching(identifier: "portfolioNetWorth").firstMatch
    }

    var cashBalanceLabel: XCUIElement {
        app.staticTexts.matching(identifier: "portfolioCash").firstMatch
    }

    var holdingsValueLabel: XCUIElement {
        app.staticTexts.matching(identifier: "holdingsValue").firstMatch
    }

    var totalProfitLossLabel: XCUIElement {
        app.staticTexts.matching(identifier: "totalProfitLoss").firstMatch
    }

    var holdingsList: XCUIElement {
        app.otherElements["holdingsList"].firstMatch
    }

    var emptyPortfolioMessage: XCUIElement {
        app.staticTexts["emptyPortfolioMessage"].firstMatch
    }

    func holdingRow(symbol: String) -> XCUIElement {
        app.otherElements["holding_\(symbol)"].firstMatch
    }

    func holdingQuantity(symbol: String) -> XCUIElement {
        app.staticTexts["holdingQty_\(symbol)"].firstMatch
    }

    func holdingValue(symbol: String) -> XCUIElement {
        app.staticTexts["holdingValue_\(symbol)"].firstMatch
    }

    func holdingProfitLoss(symbol: String) -> XCUIElement {
        app.staticTexts["holdingPL_\(symbol)"].firstMatch
    }

    func sellButton(symbol: String) -> XCUIElement {
        // The holding card itself is the button to sell (tapping it opens sell sheet)
        holdingRow(symbol: symbol)
    }

    var sellSheet: XCUIElement {
        app.sheets["sellSheet"].firstMatch
    }

    var sellQuantityTextField: XCUIElement {
        app.textFields["sellQuantityInput"].firstMatch
    }

    var sellPercentageButtons: XCUIElement {
        app.otherElements["sellPercentageButtons"].firstMatch
    }

    func sellPercentageButton(_ percentage: Int) -> XCUIElement {
        app.buttons["sellPercent_\(percentage)"].firstMatch
    }

    var sellConfirmButton: XCUIElement {
        app.buttons["confirmSellButton"].firstMatch
    }

    var sellCancelButton: XCUIElement {
        app.buttons["cancelSellButton"].firstMatch
    }

    var transactionsTab: XCUIElement {
        app.buttons["transactionsTab"].firstMatch
    }

    var transactionsList: XCUIElement {
        app.otherElements["transactionsList"].firstMatch
    }

    // MARK: - Actions

    func navigate() {
        portfolioTab.tapAfterWaiting()
    }

    func tapHolding(symbol: String) {
        holdingRow(symbol: symbol).tapAfterWaiting()
    }

    func tapSell(symbol: String) {
        sellButton(symbol: symbol).tapAfterWaiting()
    }

    func enterSellQuantity(_ quantity: String) {
        sellQuantityTextField.tapAfterWaiting()
        sellQuantityTextField.typeText(quantity)
    }

    func tapSellPercentage(_ percentage: Int) {
        sellPercentageButton(percentage).tapAfterWaiting()
    }

    func confirmSell() {
        sellConfirmButton.tapAfterWaiting()
    }

    func cancelSell() {
        sellCancelButton.tapAfterWaiting()
    }

    func switchToTransactions() {
        transactionsTab.tapAfterWaiting()
    }

    func pullToRefresh() {
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(2)
    }

    // MARK: - Verifications

    func verifyScreenVisible() -> Bool {
        return portfolioTab.isSelected || holdingsList.waitForExistence(timeout: 5)
    }

    func getNetWorth() -> String {
        return netWorthLabel.textValue
    }

    func getCashBalance() -> String {
        return cashBalanceLabel.textValue
    }

    func getHoldingsValue() -> String {
        return holdingsValueLabel.textValue
    }

    func getTotalProfitLoss() -> String {
        return totalProfitLossLabel.textValue
    }

    func hasHoldings() -> Bool {
        return !emptyPortfolioMessage.exists
    }

    func isHoldingVisible(symbol: String) -> Bool {
        return holdingRow(symbol: symbol).exists
    }

    func getHoldingCount() -> Int {
        return app.otherElements.matching(identifier: "holding_*").count
    }

    func sellHolding(symbol: String, percentage: Int) -> Bool {
        tapSell(symbol: symbol)

        guard sellSheet.waitForExistence(timeout: 3) else {
            return false
        }

        tapSellPercentage(percentage)
        confirmSell()

        // Wait for sheet to dismiss
        sleep(1)

        return !sellSheet.exists
    }

    func sellHoldingByQuantity(symbol: String, quantity: String) -> Bool {
        tapSell(symbol: symbol)

        guard sellSheet.waitForExistence(timeout: 3) else {
            return false
        }

        enterSellQuantity(quantity)
        confirmSell()

        // Wait for sheet to dismiss
        sleep(1)

        return !sellSheet.exists
    }
}
