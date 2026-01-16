# CoinFlip UI Test Suite

A comprehensive automated UI testing framework for the CoinFlip cryptocurrency trading app.

## Overview

This test suite provides extensive coverage of all CoinFlip features with a focus on data consistency, particularly net worth calculations across multiple screens. The suite generates detailed bug reports with comprehensive descriptions to help identify and fix issues quickly.

## Test Suite Structure

```
CoinFlipUITests/
├── Helpers/
│   ├── XCUIElementExtensions.swift      # Enhanced UI element interactions
│   ├── TestReporter.swift                # Comprehensive bug reporting
│   └── UITestBase.swift                  # Base test class with common utilities
├── PageObjects/
│   ├── HomeScreen.swift                  # Home screen page object
│   ├── PortfolioScreen.swift            # Portfolio screen page object
│   ├── LeaderboardScreen.swift          # Leaderboard screen page object
│   ├── ProfileScreen.swift              # Profile screen page object
│   ├── UsernameSetupScreen.swift        # ⭐️ Onboarding username setup
│   └── OnboardingScreen.swift           # ⭐️ Onboarding tutorial
├── TestCases/
│   ├── OnboardingTests.swift            # 🆕 User onboarding flow tests
│   ├── EndToEndTests.swift              # 🆕⭐️ Complete user journey tests
│   ├── DataConsistencyTests.swift       # ⭐️ Critical consistency tests
│   ├── EndToEndWorkflowTests.swift      # ⭐️ Complete user journeys
│   ├── HomeScreenTests.swift            # Home screen functionality
│   ├── PortfolioScreenTests.swift       # Portfolio functionality
│   ├── LeaderboardScreenTests.swift     # Leaderboard functionality
│   └── ProfileScreenTests.swift         # Profile functionality
├── Documentation/
│   ├── ONBOARDING_SETUP.md              # 🆕 Onboarding test setup guide
│   └── END_TO_END_TESTS.md              # 🆕 End-to-end test documentation
├── CoinFlipUITestRunner.swift           # Master test runner
└── README.md                             # This file
```

## Key Features

### 1. Comprehensive Bug Reporting

Every test failure generates a detailed bug report including:
- **Severity**: Critical, High, Medium, or Low
- **Category**: Data Consistency, Functionality, UI/UX, Performance, etc.
- **Description**: Clear explanation of the issue
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happened
- **Steps to Reproduce**: Detailed reproduction steps
- **Screenshots**: Visual evidence of the issue
- **Additional Context**: Relevant data and values

### 2. Data Consistency Validation

The most critical tests focus on verifying data consistency:
- Net worth values across Home, Portfolio, Leaderboard, and Profile screens
- Cash balance consistency after buy/sell operations
- Holdings value calculations
- Consistency after pull-to-refresh operations

### 3. End-to-End Workflows

Realistic user scenarios including:
- Complete buy/sell cycles
- Reset portfolio workflows
- Multiple coin purchases
- Partial and complete sell operations
- Rapid transaction sequences

### 4. Page Object Pattern

Clean, maintainable test code using Page Objects:
- Encapsulates screen-specific logic
- Reusable across multiple tests
- Easy to update when UI changes

## Running the Tests

### Prerequisites
- Xcode 15.0 or later
- iOS Simulator (iPhone 15 recommended)
- CoinFlip app built for testing

### Via Xcode

1. Open `CoinFlip.xcodeproj`
2. Select a simulator (e.g., iPhone 15)
3. Open Test Navigator (Cmd+6)
4. Click the play button next to "CoinFlipUITests" to run all tests
5. Or expand and run individual test classes

### Via Command Line

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

# Run specific test method
xcodebuild test \
  -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
```

## Priority Tests

If you have limited time, run these tests first:

### 🆕 0. Complete End-to-End Journey (Recommended)
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests
```

**NEW! This comprehensive test suite validates the complete user journey from onboarding through all major features**, including buy/sell operations, data consistency, and cross-screen validation. Run this first for maximum coverage.

### 1. Critical Data Consistency Test
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
```

This is **THE MOST IMPORTANT TEST** - it validates that net worth is consistent across all screens (Home, Portfolio, Leaderboard, Profile).

### 2. Complete User Journey Test
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/EndToEndWorkflowTests/testCompleteUserJourney_ResetBuySell
```

This simulates the exact scenario reported by users: Reset → Buy multiple coins → Sell all → Verify consistency.

### 3. Post-Sell Consistency Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAfterSell

xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAfterCompleteSell
```

These verify consistency after partial and complete sell operations.

## Test Coverage

### 🆕 OnboardingTests
- `testCompleteOnboardingJourneyWithValidUsername` - Full onboarding flow
- `testInvalidUsernameValidation` - Username validation rules
- `testAvatarSelection` - Avatar picker functionality
- `testUsernameSetupUIElements` - UI elements presence
- `testStartingBalanceAfterOnboarding` - Verify $1,000 starting balance

**Documentation**: See `ONBOARDING_SETUP.md` for detailed setup guide

### 🆕 EndToEndTests (⭐️ Comprehensive Journey Tests)
- `testCompleteEndToEndJourneyFromUserCreation` - Complete flow from user creation to all features
  - ✅ Onboarding flow
  - ✅ Initial portfolio state
  - ✅ Buy operations
  - ✅ Sell operations
  - ✅ Data consistency across all screens
  - ✅ Leaderboard integration
  - ✅ Profile information
- `testEndToEndWithExistingUserPortfolioReset` - All features with existing user + portfolio reset
  - ✅ Portfolio reset to clean state
  - ✅ Buy/sell operations
  - ✅ Navigate all tabs
  - ✅ Pull-to-refresh
  - ✅ Final data consistency

**Documentation**: See `END_TO_END_TESTS.md` for complete details

### DataConsistencyTests (⭐️ Most Important)
- `testNetWorthConsistencyAcrossAllScreens` - Validates consistency across all 4 screens
- `testNetWorthConsistencyAfterBuy` - After buy operations
- `testNetWorthConsistencyAfterSell` - After partial sell
- `testNetWorthConsistencyAfterCompleteSell` - After 100% sell
- `testNetWorthConsistencyAfterRefresh` - After pull-to-refresh
- `testCashBalanceConsistencyAcrossScreens` - Cash consistency
- `testCashBalanceConsistencyAfterBuyAndSell` - Cash after full cycle

### EndToEndWorkflowTests (⭐️ Critical)
- `testCompleteUserJourney_ResetBuySell` - Full reset/buy/sell workflow
- `testBuyAndHoldMultipleCoins` - Multiple holdings management
- `testPartialSellsWorkflow` - Progressive selling (25% increments)
- `testRapidBuySellCycle` - Rapid transactions

### HomeScreenTests
- Initial load and display validation
- Buy operations (single, multiple, insufficient funds)
- Cancel buy operation
- Pull-to-refresh
- Net worth and daily change display

### PortfolioScreenTests
- Holdings display and calculations
- Sell operations (25%, 50%, 75%, 100%)
- Cancel sell operation
- Net worth calculation validation
- Empty portfolio state

### LeaderboardScreenTests
- Leaderboard entries display
- Current user card
- Net worth sync with other screens
- Updates after transactions
- Rank display

### ProfileScreenTests
- Profile display (username, stats, rank)
- Reset portfolio functionality
- Cancel reset
- Settings (theme toggle)
- Net worth sync after operations

## Understanding Test Results

### Console Output

Tests produce detailed console output with emoji markers:

- 🧪 Test starting
- ✅ Test passed / Operation successful
- ❌ Test failed / Bug detected
- 🔍 Investigating / Checking
- 💰 Financial operation
- 📊 Data verification
- 🏠 Home screen action
- 💼 Portfolio screen action
- 🏆 Leaderboard screen action
- 👤 Profile screen action

### Test Report

After all tests complete, a comprehensive report is generated showing:

1. **Test Execution Summary**
   - Total tests run
   - Pass/fail counts
   - Pass rate percentage

2. **Bug Summary**
   - Total bugs found
   - Breakdown by severity (Critical, High, Medium, Low)

3. **Test Details**
   - Each test with status and duration

4. **Detailed Bug Reports**
   - For each bug:
     - Severity and category
     - Full description
     - Expected vs actual behavior
     - Step-by-step reproduction instructions
     - Device information
     - Screenshots (attached to Xcode results)
     - Additional context data

The report is:
- Printed to console
- Saved to Documents directory as `CoinFlipTestReport.txt`
- Included in Xcode test results

## Interpreting Bug Reports

### Bug Severity Levels

- **🔴 CRITICAL**: Data loss, crashes, or major functionality broken
  - Example: Net worth inconsistency across screens
  - Action: Fix immediately

- **🟠 HIGH**: Important feature not working correctly
  - Example: Buy/sell operations failing
  - Action: Fix before next release

- **🟡 MEDIUM**: Minor functionality issues or poor UX
  - Example: Missing labels or incorrect formatting
  - Action: Fix in next sprint

- **🟢 LOW**: Cosmetic issues or minor improvements
  - Example: Slightly misaligned UI elements
  - Action: Add to backlog

### Bug Categories

- **Data Consistency**: Values don't match across screens
- **Functionality**: Features don't work as expected
- **UI/UX**: Display or interaction issues
- **Performance**: Slow operations or timeouts
- **Crash**: App terminates unexpectedly
- **Authentication**: User auth issues
- **Network**: API or connectivity problems

## Troubleshooting

### Tests Fail to Launch
```bash
# Clean build folder and retry
xcodebuild clean -scheme CoinFlip
xcodebuild build -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Element Not Found Errors
1. Check that accessibility identifiers are set in the app code
2. Verify the element exists by inspecting the UI in Xcode's Accessibility Inspector
3. Increase timeout values in `UITestBase.swift` if needed

### Inconsistent Test Results
1. Reset the simulator: Device → Erase All Content and Settings
2. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/CoinFlip-*`
3. Restart Xcode and simulator

### Timeout Errors
- Increase wait timeout in individual tests
- Check for slow network requests
- Verify mock data is being used (set `USE_MOCK_DATA=1` environment variable)

### Screenshot Captures
Screenshots are automatically captured on test failures and attached to test results. View them in Xcode's Test Report Navigator.

## Adding New Tests

### 1. Create a Test Class

```swift
import XCTest

final class MyNewTests: UITestBase {

    var screen: MyScreen!

    override func setUpWithError() throws {
        try super.setUpWithError()
        screen = MyScreen(app: app)
    }

    override func tearDownWithError() throws {
        screen = nil
        try super.tearDownWithError()
    }

    func testMyFeature() {
        // Your test code here
    }
}
```

### 2. Use Enhanced Assertions

```swift
// Element existence
assertElementExists(element, "Element should be visible")

// Text content
assertText(element, contains: "Expected text")

// Value matching
assertValue(element, equals: "Expected value")

// Data consistency
assertDataConsistency(
    description: "Values should match",
    values: ["Screen1": value1, "Screen2": value2]
)
```

### 3. Report Bugs

```swift
reporter.reportBug(
    testName: testName,
    severity: .critical,
    category: .dataConsistency,
    description: "Clear description of the bug",
    expectedBehavior: "What should happen",
    actualBehavior: "What actually happened",
    stepsToReproduce: [
        "Step 1",
        "Step 2",
        "Step 3"
    ],
    screenshot: XCUIScreen.main.screenshot(),
    additionalContext: ["Key": "Value"]
)
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: UI Tests
on: [push, pull_request]

jobs:
  ui-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -scheme CoinFlip \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:CoinFlipUITests \
            | tee test-output.log

      - name: Upload Test Results
        uses: actions/upload-artifact@v2
        if: always()
        with:
          name: test-results
          path: |
            test-output.log
            ~/Library/Developer/Xcode/DerivedData/**/Logs/Test/*.xcresult
```

## Best Practices

1. **Run critical tests frequently** during development
2. **Run full suite** before merging PRs
3. **Review bug reports carefully** - they contain valuable debugging information
4. **Update tests** when UI changes
5. **Add new tests** for new features
6. **Keep tests isolated** - each test should be independent
7. **Use meaningful test names** that describe what's being tested
8. **Document complex test scenarios** with comments

## Maintenance

### Updating Page Objects

When UI changes, update the corresponding Page Object:

```swift
// Old
var oldButton: XCUIElement {
    app.buttons["oldIdentifier"]
}

// New
var newButton: XCUIElement {
    app.buttons["newIdentifier"]
}
```

### Updating Test Expectations

When app behavior changes intentionally:

1. Update the test's expected behavior
2. Update the assertion
3. Document the change

### Removing Obsolete Tests

If a feature is removed:

1. Delete the corresponding tests
2. Update related end-to-end tests
3. Document in commit message

## Support

For questions or issues with the test suite:

1. Check this README for common solutions
2. Review test code comments for specific test details
3. Consult the UITestBase class for available helper methods
4. Check XCUIElement extensions for enhanced interactions

## License

Part of the CoinFlip project. See main project LICENSE file.

---

**Happy Testing! 🧪✅**
