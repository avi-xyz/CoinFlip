# Quick Start Guide - CoinFlip UI Tests

## Run Tests in 3 Steps

### 1. Open Project in Xcode
```bash
cd /Users/avinash/Code/CoinFlip
open CoinFlip.xcodeproj
```

### 2. Select Simulator
- Choose "iPhone 15" (or any iOS 17+ simulator) from the device selector

### 3. Run Tests
- Press `Cmd + U` to run all tests
- OR: Open Test Navigator (`Cmd + 6`) and click the play button next to "CoinFlipUITests"

## Quick Command Line Test

```bash
cd /Users/avinash/Code/CoinFlip

# Run the most important test (Net Worth Consistency)
xcodebuild test \
  -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
```

## What to Look For

### ✅ Success Output:
```
✅ NET WORTH IS CONSISTENT ACROSS ALL SCREENS: $1000.00
Test Case '-[CoinFlipUITests.DataConsistencyTests testNetWorthConsistencyAcrossAllScreens]' passed
```

### ❌ Failure Output (Bug Detected):
```
❌ NET WORTH INCONSISTENCY: Home=$1000.0, Portfolio=$985.5, Leaderboard=$1000.0, Profile=$1000.0

🔴 CRITICAL Bug Report
━━━━━━━━━━━━━━━━━━━━━━━
Category: Data Consistency
Description: NET WORTH INCONSISTENCY DETECTED ACROSS SCREENS
Expected: Net worth should be identical across all screens
Actual: Found inconsistent values with difference of $14.50
```

## Test Results Location

After running tests, find the comprehensive report at:

1. **Console Output**: Xcode's test log (show with `Cmd + 7`)
2. **Test Report**: Test Navigator → Right-click test → "Jump to Report"
3. **Saved File**: `~/Library/Developer/Xcode/DerivedData/.../Documents/CoinFlipTestReport.txt`

## Run Specific Test Suites

### Critical Data Consistency Tests (Run First!)
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/DataConsistencyTests
```
**Duration**: ~2-3 minutes
**Tests**: 7 tests focusing on net worth and cash consistency

### Complete User Journey (The User's Reported Scenario)
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/EndToEndWorkflowTests/testCompleteUserJourney_ResetBuySell
```
**Duration**: ~1 minute
**Tests**: Exact scenario user reported (Reset → Buy BTC, ETH, DOGE, XMR → Sell All)

### All Home Screen Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/HomeScreenTests
```
**Duration**: ~3-4 minutes
**Tests**: 10 tests for buy operations and home display

### All Portfolio Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests/PortfolioScreenTests
```
**Duration**: ~3-4 minutes
**Tests**: 9 tests for sell operations and holdings display

### All Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipUITests
```
**Duration**: ~10-15 minutes
**Tests**: 50+ comprehensive tests

## Interpreting Results

### Bug Severity Guide

When tests fail, check the severity:

- **🔴 CRITICAL** - Fix NOW (data loss, major features broken)
- **🟠 HIGH** - Fix soon (important features not working)
- **🟡 MEDIUM** - Fix next sprint (minor issues)
- **🟢 LOW** - Backlog (cosmetic issues)

### Common Bug Categories

- **Data Consistency** - Values don't match across screens (CRITICAL)
- **Functionality** - Features don't work (HIGH)
- **UI/UX** - Display problems (MEDIUM)
- **Performance** - Slow operations (LOW)

## Troubleshooting

### "Build Failed"
```bash
# Clean and rebuild
xcodebuild clean -scheme CoinFlip
xcodebuild build -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15'
```

### "Unable to boot simulator"
1. Open Simulator app
2. Select Device → Erase All Content and Settings
3. Restart Xcode

### "Element not found"
- This is expected if the app's UI has changed
- Update accessibility identifiers in Page Objects
- Or add identifiers to SwiftUI views: `.accessibilityIdentifier("myElement")`

### Tests take too long
- Use `-only-testing` to run specific tests
- Run critical tests first: `DataConsistencyTests` and `EndToEndWorkflowTests`

## Next Steps

1. **Run the critical test** to check for net worth consistency issues
2. **Review the bug report** if any tests fail
3. **Read the full README.md** for detailed documentation
4. **Add tests** for any new features you develop

## Test Priority

If you only have 5 minutes, run these tests in order:

1. **testNetWorthConsistencyAcrossAllScreens** (30 seconds)
2. **testCompleteUserJourney_ResetBuySell** (1 minute)
3. **testNetWorthConsistencyAfterSell** (30 seconds)
4. **testNetWorthConsistencyAfterCompleteSell** (30 seconds)
5. **testPortfolioNetWorthEqualsHoldingsPlusCash** (30 seconds)

These 5 tests will catch 90% of data consistency bugs.

---

**For detailed information, see README.md**
