//
//  OnboardingScreen.swift
//  CoinFlipUITests
//
//  Page Object for Onboarding/Tutorial Screen
//

import XCTest

class OnboardingScreen {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var skipButton: XCUIElement {
        app.buttons["Skip"]
    }

    var nextButton: XCUIElement {
        app.buttons["Next"]
    }

    var getStartedButton: XCUIElement {
        app.buttons["Get Started"]
    }

    // MARK: - Actions

    func tapSkip() {
        skipButton.tapAfterWaiting()
    }

    func tapNext() {
        nextButton.tapAfterWaiting()
    }

    func tapGetStarted() {
        getStartedButton.tapAfterWaiting()
    }

    // MARK: - Verifications

    func verifyScreenVisible() -> Bool {
        return skipButton.waitForExistence(timeout: 5) ||
               nextButton.waitForExistence(timeout: 5) ||
               getStartedButton.waitForExistence(timeout: 5)
    }

    // MARK: - Complete flow

    func skipOnboarding() -> Bool {
        guard verifyScreenVisible() else {
            return false
        }

        // If skip button is visible, tap it
        if skipButton.exists {
            tapSkip()
            // Wait for onboarding to dismiss
            sleep(2)
            return true
        }

        // If get started is visible, we're on last page
        if getStartedButton.exists {
            tapGetStarted()
            // Wait for onboarding to dismiss
            sleep(2)
            return true
        }

        return false
    }

    func completeOnboarding() -> Bool {
        guard verifyScreenVisible() else {
            return false
        }

        // Go through all pages
        while nextButton.exists {
            tapNext()
            sleep(1)
        }

        // Tap get started on final page
        if getStartedButton.exists {
            tapGetStarted()
            return true
        }

        return false
    }
}
