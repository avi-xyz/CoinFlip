//
//  LeaderboardScreen.swift
//  CoinFlipUITests
//
//  Page Object for Leaderboard Screen
//

import XCTest

class LeaderboardScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var leaderboardTab: XCUIElement {
        app.tabBars.buttons["Leaderboard"]
    }

    var leaderboardTitle: XCUIElement {
        app.staticTexts["leaderboardTitle"].firstMatch
    }

    var leaderboardList: XCUIElement {
        app.otherElements["leaderboardList"].firstMatch
    }

    var currentUserCard: XCUIElement {
        app.otherElements["currentUserCard"].firstMatch
    }

    var currentUserRank: XCUIElement {
        app.staticTexts["currentUserRank"].firstMatch
    }

    var currentUserNetWorth: XCUIElement {
        app.staticTexts["currentUserNetWorth"].firstMatch
    }

    var currentUserGain: XCUIElement {
        app.staticTexts["currentUserGain"].firstMatch
    }

    func leaderboardEntry(rank: Int) -> XCUIElement {
        app.otherElements["leaderboardEntry_\(rank)"].firstMatch
    }

    func entryUsername(rank: Int) -> XCUIElement {
        app.staticTexts["entryUsername_\(rank)"].firstMatch
    }

    func entryNetWorth(rank: Int) -> XCUIElement {
        app.staticTexts["entryNetWorth_\(rank)"].firstMatch
    }

    func entryGain(rank: Int) -> XCUIElement {
        app.staticTexts["entryGain_\(rank)"].firstMatch
    }

    var refreshControl: XCUIElement {
        app.otherElements["refreshControl"].firstMatch
    }

    // MARK: - Actions

    func navigate() {
        leaderboardTab.tapAfterWaiting()
    }

    func tapEntry(rank: Int) {
        leaderboardEntry(rank: rank).tapAfterWaiting()
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
        return leaderboardTab.isSelected || leaderboardList.waitForExistence(timeout: 5)
    }

    func getCurrentUserRank() -> String {
        return currentUserRank.textValue
    }

    func getCurrentUserNetWorth() -> String {
        return currentUserNetWorth.textValue
    }

    func getCurrentUserGain() -> String {
        return currentUserGain.textValue
    }

    func isEntryVisible(rank: Int) -> Bool {
        return leaderboardEntry(rank: rank).exists
    }

    func getLeaderboardEntryCount() -> Int {
        return app.otherElements.matching(identifier: "leaderboardEntry_*").count
    }

    func getUsernameAt(rank: Int) -> String {
        return entryUsername(rank: rank).textValue
    }

    func getNetWorthAt(rank: Int) -> String {
        return entryNetWorth(rank: rank).textValue
    }

    func getGainAt(rank: Int) -> String {
        return entryGain(rank: rank).textValue
    }
}
