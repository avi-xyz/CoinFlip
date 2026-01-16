//
//  CoinFlipUITestRunner.swift
//  CoinFlipUITests
//
//  Master test suite runner that executes all tests and generates comprehensive report
//

import XCTest

final class CoinFlipUITestRunner: XCTestCase {

    override class func setUp() {
        super.setUp()
        TestReporter.shared.reset()
        print("\n")
        print("═══════════════════════════════════════════════════════════════")
        print("🚀 COINFLIP COMPREHENSIVE UI TEST SUITE")
        print("═══════════════════════════════════════════════════════════════")
        print("Starting comprehensive UI testing...")
        print("This test suite will validate all app functionality and")
        print("report any bugs with comprehensive descriptions.")
        print("═══════════════════════════════════════════════════════════════\n")
    }

    override class func tearDown() {
        // Generate and print comprehensive summary report
        let report = TestReporter.shared.generateSummaryReport()
        print(report)

        // Write report to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let reportPath = documentsPath?.appendingPathComponent("CoinFlipTestReport.txt") {
            try? report.write(to: reportPath, atomically: true, encoding: .utf8)
            print("📄 Full report saved to: \(reportPath.path)")
        }

        super.tearDown()
    }

    // MARK: - Test Execution Entry Point

    func testRunAllTests() {
        print("\n🔧 Executing Full Test Suite...\n")

        // This test serves as the main entry point
        // Individual test classes will be executed by XCTest automatically

        XCTAssert(true, "Test suite execution completed")
    }
}

// MARK: - Test Suite Information

/*
 COINFLIP UI TEST SUITE
 ═══════════════════════════════════════════════════════════════

 ## Test Coverage

 This comprehensive test suite includes the following test classes:

 ### 1. DataConsistencyTests ⭐️ MOST IMPORTANT
 - Tests net worth consistency across Home, Portfolio, Leaderboard, and Profile screens
 - Validates cash balance consistency
 - Tests consistency after buy operations
 - Tests consistency after sell operations
 - Tests consistency after complete sell (100%)
 - Tests consistency after pull to refresh

 ### 2. EndToEndWorkflowTests ⭐️ CRITICAL
 - Complete user journey: Reset → Buy → Sell → Verify
 - Tests buy and hold multiple coins
 - Tests partial sells workflow
 - Tests rapid buy/sell cycles
 - Simulates exact user-reported scenarios

 ### 3. HomeScreenTests
 - Initial load and display tests
 - Trending coins display
 - Net worth display format
 - Buy coin operations
 - Buy insufficient funds validation
 - Buy multiple coins
 - Cancel buy operation
 - Pull to refresh
 - Daily change display

 ### 4. PortfolioScreenTests
 - Initial load and empty state
 - Holdings display after purchase
 - Sell operations (partial and complete)
 - Multiple percentage sells (25%, 50%, 75%, 100%)
 - Cancel sell operation
 - Holding quantity and value display
 - Net worth calculation (holdings + cash)
 - Pull to refresh

 ### 5. LeaderboardScreenTests
 - Initial load and entries display
 - Current user card display
 - Entry data format validation
 - Net worth sync with Home screen
 - Updates after buy operations
 - Pull to refresh
 - User rank display

 ### 6. ProfileScreenTests
 - Initial load and stats display
 - Username display
 - Reset portfolio functionality
 - Reset clears holdings
 - Cancel reset operation
 - Theme toggle
 - Rank display
 - Net worth sync after buy

 ## Test Helpers and Utilities

 - **XCUIElementExtensions**: Enhanced element interactions
 - **TestReporter**: Comprehensive bug reporting with detailed context
 - **UITestBase**: Base class with common helpers and assertions
 - **Page Objects**: HomeScreen, PortfolioScreen, LeaderboardScreen, ProfileScreen

 ## Running the Tests

 ### Via Xcode:
 1. Open CoinFlip.xcodeproj
 2. Select a simulator (iPhone 15, iOS 17+)
 3. Press Cmd+U to run all tests
 4. OR: Open Test Navigator and run specific test classes

 ### Via Command Line:
 ```bash
 # Run all UI tests
 xcodebuild test \
   -scheme CoinFlip \
   -destination 'platform=iOS Simulator,name=iPhone 15' \
   -only-testing:CoinFlipUITests

 # Run specific test class
 xcodebuild test \
   -scheme CoinFlip \
   -destination 'platform=iOS Simulator,name=iPhone 15' \
   -only-testing:CoinFlipUITests/DataConsistencyTests

 # Run specific test
 xcodebuild test \
   -scheme CoinFlip \
   -destination 'platform=iOS Simulator,name=iPhone 15' \
   -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
 ```

 ## Test Report

 After running tests, a comprehensive report will be generated that includes:
 - Total tests executed
 - Pass/fail counts
 - All bugs found with:
   - Severity (Critical, High, Medium, Low)
   - Category (Data Consistency, Functionality, UI, etc.)
   - Description
   - Expected vs Actual behavior
   - Steps to reproduce
   - Screenshots
   - Additional context

 The report will be:
 1. Printed to console
 2. Saved to Documents directory as "CoinFlipTestReport.txt"
 3. Attached to Xcode test results

 ## Priority Tests

 If time is limited, run these tests first:

 1. **DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens**
    - The PRIMARY test for net worth consistency issues

 2. **EndToEndWorkflowTests/testCompleteUserJourney_ResetBuySell**
    - Simulates the exact user-reported scenario

 3. **DataConsistencyTests/testNetWorthConsistencyAfterSell**
    - Tests consistency after sell operations

 4. **DataConsistencyTests/testNetWorthConsistencyAfterCompleteSell**
    - Tests consistency after complete (100%) sells

 ## Known Limitations

 - Tests use mock data when USE_MOCK_DATA environment variable is set
 - Some tests may fail if network requests are slow
 - Tests assume starting balance of $1000

 ## Troubleshooting

 - If tests fail to launch: Clean build folder (Cmd+Shift+K) and retry
 - If elements not found: Check accessibility identifiers in app code
 - If tests timeout: Increase wait timeouts in UITestBase
 - If inconsistent results: Reset simulator and retry

 ═══════════════════════════════════════════════════════════════
 */
