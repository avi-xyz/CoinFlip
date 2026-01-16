//
//  UsernameSetupScreen.swift
//  CoinFlipUITests
//
//  Page Object for Username Setup Screen (Onboarding)
//

import XCTest

class UsernameSetupScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var usernameTextField: XCUIElement {
        app.textFields["usernameTextField"]
    }

    var startTradingButton: XCUIElement {
        app.buttons["startTradingButton"]
    }

    func avatarButton(emoji: String) -> XCUIElement {
        app.buttons["avatarEmoji_\(emoji)"]
    }

    var welcomeTitle: XCUIElement {
        app.staticTexts["Welcome to CoinFlip!"]
    }

    var chooseUsernameLabel: XCUIElement {
        app.staticTexts["Choose Username"]
    }

    var pickAvatarLabel: XCUIElement {
        app.staticTexts["Pick Your Avatar"]
    }

    // MARK: - Actions

    func enterUsername(_ username: String) {
        usernameTextField.tapAfterWaiting()
        usernameTextField.typeText(username)
    }

    func selectAvatar(_ emoji: String) {
        avatarButton(emoji: emoji).tapAfterWaiting()
    }

    func tapStartTrading() {
        startTradingButton.tapAfterWaiting()
    }

    // MARK: - Verifications

    func verifyScreenVisible() -> Bool {
        return welcomeTitle.waitForExistence(timeout: 10) ||
               usernameTextField.waitForExistence(timeout: 10)
    }

    func isStartTradingEnabled() -> Bool {
        return startTradingButton.isEnabled
    }

    // MARK: - Complete flow

    func completeSetup(username: String, emoji: String) -> Bool {
        guard verifyScreenVisible() else {
            print("❌ Username setup screen not visible")
            return false
        }

        enterUsername(username)
        sleep(1)

        selectAvatar(emoji)
        sleep(1)

        guard isStartTradingEnabled() else {
            print("❌ Start Trading button is not enabled")
            return false
        }

        tapStartTrading()

        // Wait for screen to transition to main app
        let tabBar = app.tabBars.firstMatch
        return tabBar.waitForExistence(timeout: 15)
    }
}
