//
//  HomeScreen.swift
//  CoinFlipUITests
//
//  Page Object for Home Screen
//

import XCTest

class HomeScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var netWorthLabel: XCUIElement {
        app.staticTexts.matching(identifier: "netWorthValue").firstMatch
    }

    var cashBalanceLabel: XCUIElement {
        app.staticTexts.matching(identifier: "cashBalance").firstMatch
    }

    var dailyChangeLabel: XCUIElement {
        app.staticTexts.matching(identifier: "dailyChange").firstMatch
    }

    var featuredCoinCard: XCUIElement {
        app.otherElements["featuredCoinCard"].firstMatch
    }

    var trendingCoinsSection: XCUIElement {
        app.otherElements["trendingCoinsSection"].firstMatch
    }

    func coinRow(symbol: String) -> XCUIElement {
        app.otherElements["coinRow_\(symbol)"].firstMatch
    }

    func coinPrice(symbol: String) -> XCUIElement {
        app.staticTexts["coinPrice_\(symbol)"].firstMatch
    }

    func buyCoinButton(symbol: String) -> XCUIElement {
        app.buttons["buyCoin_\(symbol)"].firstMatch
    }

    var buySheet: XCUIElement {
        app.sheets["buySheet"].firstMatch
    }

    var buyAmountTextField: XCUIElement {
        app.textFields["buyAmountInput"].firstMatch
    }

    var buyConfirmButton: XCUIElement {
        app.buttons["confirmBuyButton"].firstMatch
    }

    var buyCancelButton: XCUIElement {
        app.buttons["cancelBuyButton"].firstMatch
    }

    var refreshControl: XCUIElement {
        app.otherElements["refreshControl"].firstMatch
    }

    // MARK: - Actions

    func tapCoin(symbol: String) {
        coinRow(symbol: symbol).tapAfterWaiting()
    }

    func tapBuyCoin(symbol: String) {
        // Wait for coins to load first
        let button = buyCoinButton(symbol: symbol)

        // Longer timeout for button to appear (coins load from API)
        if !button.waitForExistence(timeout: 10) {
            print("⚠️ Buy button for \(symbol) not found after 10s. Trying to find any coin card...")
            // Try alternative: look for any element with the identifier
            let anyElement = app.descendants(matching: .any).matching(identifier: "buyCoin_\(symbol)").firstMatch
            if anyElement.waitForExistence(timeout: 5) {
                anyElement.tap()
                return
            }
        }

        button.tap()
    }

    func enterBuyAmount(_ amount: String) {
        buyAmountTextField.tapAfterWaiting()
        buyAmountTextField.typeText(amount)
    }

    func confirmBuy() {
        buyConfirmButton.tapAfterWaiting()
    }

    func cancelBuy() {
        buyCancelButton.tapAfterWaiting()
    }

    func pullToRefresh() {
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(2) // Wait for refresh
    }

    // MARK: - Verifications

    func verifyScreenVisible() -> Bool {
        // First wait for net worth to appear (always shows)
        if netWorthLabel.waitForExistence(timeout: 10) {
            return true
        }

        // Then check for coin cards (may take time to load)
        return featuredCoinCard.waitForExistence(timeout: 10) ||
               buyCoinButton(symbol: "BTC").waitForExistence(timeout: 10) ||
               buyCoinButton(symbol: "ETH").waitForExistence(timeout: 10)
    }

    func getNetWorth() -> String {
        return netWorthLabel.textValue
    }

    func getCashBalance() -> String {
        return cashBalanceLabel.textValue
    }

    func getDailyChange() -> String {
        return dailyChangeLabel.textValue
    }

    func isCoinVisible(symbol: String) -> Bool {
        return coinRow(symbol: symbol).exists
    }

    func buyCoin(symbol: String, amount: String) -> Bool {
        tapBuyCoin(symbol: symbol)

        guard buySheet.waitForExistence(timeout: 3) else {
            return false
        }

        enterBuyAmount(amount)
        confirmBuy()

        // Wait for sheet to dismiss
        sleep(1)

        return !buySheet.exists
    }
}
