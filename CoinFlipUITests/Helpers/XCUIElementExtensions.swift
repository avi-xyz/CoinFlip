//
//  XCUIElementExtensions.swift
//  CoinFlipUITests
//
//  Helper extensions for XCUIElement to improve test readability and reliability
//

import XCTest

extension XCUIElement {

    /// Wait for element to exist with timeout
    @discardableResult
    func waitForExistence(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> Bool {
        let exists = self.waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Element '\(self.identifier)' did not exist after \(timeout) seconds", file: file, line: line)
        }
        return exists
    }

    /// Wait for element to be hittable (visible and enabled)
    @discardableResult
    func waitToBeHittable(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Element '\(self.identifier)' was not hittable after \(timeout) seconds", file: file, line: line)
            return false
        }
        return true
    }

    /// Tap element after waiting for it to be hittable
    func tapAfterWaiting(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        waitToBeHittable(timeout: timeout, file: file, line: line)
        tap()
    }

    /// Type text after waiting for element
    func typeTextAfterWaiting(_ text: String, timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        waitToBeHittable(timeout: timeout, file: file, line: line)
        tap()
        typeText(text)
    }

    /// Clear text field and type new text
    func clearAndTypeText(_ text: String, file: StaticString = #file, line: UInt = #line) {
        waitToBeHittable(file: file, line: line)
        tap()

        // Select all and delete
        let selectAllString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (self.value as? String)?.count ?? 0)
        typeText(selectAllString)

        typeText(text)
    }

    /// Swipe up slowly to reveal content
    func slowSwipeUp(velocity: XCUIGestureVelocity = .slow) {
        let start = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let end = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: velocity, thenHoldForDuration: 0.1)
    }

    /// Get text value from element
    var textValue: String {
        (value as? String) ?? label
    }

    /// Check if element contains text
    func containsText(_ text: String) -> Bool {
        return textValue.contains(text) || label.contains(text)
    }
}

extension XCUIElementQuery {

    /// Get element matching partial identifier
    func containing(_ identifier: String) -> XCUIElement {
        return self.matching(NSPredicate(format: "identifier CONTAINS %@", identifier)).firstMatch
    }

    /// Get element matching partial label
    func labelContaining(_ text: String) -> XCUIElement {
        return self.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Get all elements and return as array
    var allElements: [XCUIElement] {
        return (0..<count).map { self.element(boundBy: $0) }
    }
}
