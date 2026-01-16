//
//  ProfileScreen.swift
//  CoinFlipUITests
//
//  Page Object for Profile Screen
//

import XCTest

class ProfileScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var profileTab: XCUIElement {
        app.tabBars.buttons["Profile"]
    }

    var usernameLabel: XCUIElement {
        app.staticTexts["profileUsername"].firstMatch
    }

    var avatarView: XCUIElement {
        app.otherElements["profileAvatar"].firstMatch
    }

    var netWorthLabel: XCUIElement {
        app.staticTexts["profileNetWorth"].firstMatch
    }

    var rankLabel: XCUIElement {
        app.staticTexts["profileRank"].firstMatch
    }

    var gainLabel: XCUIElement {
        app.staticTexts["profileGain"].firstMatch
    }

    var statsCard: XCUIElement {
        app.otherElements["profileStatsCard"].firstMatch
    }

    var settingsSection: XCUIElement {
        app.otherElements["settingsSection"].firstMatch
    }

    var themeToggle: XCUIElement {
        app.switches["themeToggle"].firstMatch
    }

    var notificationsToggle: XCUIElement {
        app.switches["notificationsToggle"].firstMatch
    }

    var resetPortfolioButton: XCUIElement {
        app.buttons["resetPortfolioButton"].firstMatch
    }

    var resetConfirmAlert: XCUIElement {
        app.alerts["resetConfirmAlert"].firstMatch
    }

    var resetConfirmButton: XCUIElement {
        app.buttons["Confirm Reset"].firstMatch
    }

    var resetCancelButton: XCUIElement {
        app.buttons["Cancel"].firstMatch
    }

    var changeAvatarButton: XCUIElement {
        app.buttons["changeAvatarButton"].firstMatch
    }

    var avatarPicker: XCUIElement {
        app.otherElements["avatarPicker"].firstMatch
    }

    func avatarOption(_ emoji: String) -> XCUIElement {
        app.buttons["avatar_\(emoji)"].firstMatch
    }

    var signOutButton: XCUIElement {
        app.buttons["signOutButton"].firstMatch
    }

    var aboutSection: XCUIElement {
        app.otherElements["aboutSection"].firstMatch
    }

    // MARK: - Actions

    func navigate() {
        profileTab.tapAfterWaiting()
    }

    func tapResetPortfolio() {
        resetPortfolioButton.tapAfterWaiting()
    }

    func confirmReset() {
        resetConfirmButton.tapAfterWaiting()
        sleep(2) // Wait for reset to complete
    }

    func cancelReset() {
        resetCancelButton.tapAfterWaiting()
    }

    func toggleTheme() {
        themeToggle.tapAfterWaiting()
    }

    func toggleNotifications() {
        notificationsToggle.tapAfterWaiting()
    }

    func tapChangeAvatar() {
        changeAvatarButton.tapAfterWaiting()
    }

    func selectAvatar(_ emoji: String) {
        avatarOption(emoji).tapAfterWaiting()
    }

    func tapSignOut() {
        signOutButton.tapAfterWaiting()
    }

    func pullToRefresh() {
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(1)
    }

    // MARK: - Verifications

    func verifyScreenVisible() -> Bool {
        return profileTab.isSelected || usernameLabel.waitForExistence(timeout: 5)
    }

    func getUsername() -> String {
        return usernameLabel.textValue
    }

    func getNetWorth() -> String {
        return netWorthLabel.textValue
    }

    func getRank() -> String {
        return rankLabel.textValue
    }

    func getGain() -> String {
        return gainLabel.textValue
    }

    func isThemeToggleOn() -> Bool {
        return themeToggle.value as? String == "1"
    }

    func isNotificationsToggleOn() -> Bool {
        return notificationsToggle.value as? String == "1"
    }

    func isResetAlertVisible() -> Bool {
        return resetConfirmAlert.exists
    }

    func resetPortfolio() -> Bool {
        tapResetPortfolio()

        guard resetConfirmAlert.waitForExistence(timeout: 3) else {
            return false
        }

        confirmReset()

        // Wait for reset to complete
        sleep(2)

        return !resetConfirmAlert.exists
    }
}
