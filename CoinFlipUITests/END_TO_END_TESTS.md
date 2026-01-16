# End-to-End Test Suite Documentation

## Overview

Comprehensive end-to-end tests that validate the complete user journey through the CoinFlip application, from user creation to all major features.

## Test Files

- **EndToEndTests.swift** - Complete end-to-end test suite with two major test scenarios

---

## Test Scenarios

### 1. `testCompleteEndToEndJourneyFromUserCreation()`

**Purpose**: Tests the complete user journey starting from scratch (no existing user).

**Environment Setup**:
```swift
"RESET_STATE": "1"  // Fresh start, no auto-create
```

**Test Flow**:

1. **Complete Onboarding**
   - Launch app with no user
   - Verify username setup screen appears
   - Enter username: "E2ETrader"
   - Select emoji avatar: 🚀
   - Verify "Start Trading" button enabled
   - Tap "Start Trading"
   - Skip onboarding tutorial if it appears
   - Verify main app tab bar appears

2. **Verify Initial Portfolio State**
   - Navigate to Portfolio tab
   - Verify net worth = $1,000
   - Verify cash balance = $1,000
   - Confirm no holdings

3. **Navigate All Tabs**
   - Test navigation to: Home, Portfolio, Leaderboard, Profile
   - Verify each tab loads successfully

4. **Execute Buy Operations**
   - Navigate to Home screen
   - Find first available coin
   - Tap coin card
   - Enter amount: $100
   - Tap Buy button
   - Wait for transaction to complete
   - Dismiss modal

5. **Verify Portfolio After Buys**
   - Navigate to Portfolio
   - Verify at least one holding exists
   - Confirm portfolio updated correctly

6. **Execute Sell Operations**
   - Navigate to Portfolio
   - Tap first holding
   - Enter sell amount: $50
   - Tap Sell button
   - Wait for transaction to complete
   - Dismiss modal

7. **Verify Data Consistency**
   - Collect net worth from Home, Portfolio, and Profile screens
   - Assert all values match
   - Ensure data is consistent across the app

8. **Check Leaderboard Presence**
   - Navigate to Leaderboard
   - Verify at least one entry exists (our user)
   - Confirm leaderboard is populated

9. **Check Profile Information**
   - Navigate to Profile
   - Verify username = "E2ETrader"
   - Verify avatar displays correctly

**Expected Duration**: 60-90 seconds

**Success Criteria**:
- All steps complete without failures
- Net worth consistent across all screens
- Portfolio reflects buy/sell operations
- User appears on leaderboard

---

### 2. `testEndToEndWithExistingUserPortfolioReset()`

**Purpose**: Tests all features with an existing user after resetting their portfolio to a clean state.

**Environment Setup**:
```swift
"RESET_STATE": "1",
"AUTO_CREATE_TEST_USER": "1"  // Auto-create user
```

**Test Flow**:

1. **Reset Portfolio to Clean State**
   - Navigate to Portfolio
   - Sell all existing holdings one by one
   - Return to 100% cash position
   - Verify clean slate

2. **Verify Starting Balance**
   - Check net worth
   - Check cash balance
   - Confirm no holdings

3. **Test Buy Operations**
   - Buy coins from Home screen
   - Verify transactions complete

4. **Verify Portfolio After Buys**
   - Navigate to Portfolio
   - Verify holdings appear
   - Check values are correct

5. **Test Sell Operations**
   - Sell portions of holdings
   - Verify transactions complete

6. **Navigate All Features**
   - Test all tabs: Home, Portfolio, Leaderboard, Profile
   - Verify each loads correctly

7. **Test Pull-to-Refresh**
   - Navigate to Home
   - Pull down to refresh
   - Verify data reloads

8. **Verify Final Data Consistency**
   - Collect net worth from all screens
   - Assert consistency across app
   - Confirm no data discrepancies

**Expected Duration**: 50-70 seconds

**Success Criteria**:
- Portfolio successfully reset
- All buy/sell operations work
- Data remains consistent
- Pull-to-refresh functions correctly

---

## Running the Tests

### Run Both End-to-End Tests

```bash
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests
```

### Run Single Test - From User Creation

```bash
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests/testCompleteEndToEndJourneyFromUserCreation
```

### Run Single Test - With Existing User

```bash
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests/testEndToEndWithExistingUserPortfolioReset
```

---

## Key Features

### 1. Comprehensive Coverage

Tests cover:
- User onboarding flow
- Portfolio management (buy/sell)
- Navigation between all tabs
- Data consistency across screens
- Leaderboard integration
- Profile information display
- Pull-to-refresh functionality

### 2. Two Test Flavors

**From Scratch**:
- Tests complete user journey from first launch
- Validates onboarding experience
- Ensures new users can complete full workflow

**With Existing User**:
- Tests feature functionality with established user
- Validates portfolio reset capability
- Faster execution (skips onboarding)

### 3. Portfolio Reset Helper

The `resetPortfolioToCleanState()` method:
- Automatically sells all holdings
- Returns portfolio to 100% cash
- Provides clean slate for testing
- Useful for repeatable test scenarios

---

## Helper Methods

### Setup Methods

- `setupFreshApp()` - Launch with RESET_STATE only (no user)
- `setupWithExistingUser()` - Launch with RESET_STATE + AUTO_CREATE_TEST_USER

### Journey Steps

- `completeOnboarding(username:emoji:)` - Complete full onboarding flow
- `verifyInitialPortfolioState()` - Check $1,000 starting balance
- `navigateAllTabs()` - Test navigation to all tabs
- `executeBuyOperations()` - Buy coins from home screen
- `executeSellOperations()` - Sell holdings from portfolio
- `verifyDataConsistencyAcrossScreens()` - Check net worth consistency
- `verifyLeaderboardPresence()` - Confirm user on leaderboard
- `verifyProfileInformation(username:)` - Check profile details
- `resetPortfolioToCleanState()` - Sell all holdings

### Utility Methods

- `navigateToTab(_:)` - Navigate to specific tab
- `testPullToRefresh()` - Test pull-to-refresh functionality

---

## Test Structure

```
EndToEndTests
├── Test 1: From User Creation
│   ├── Step 1: Complete Onboarding
│   ├── Step 2: Verify Initial State
│   ├── Step 3: Navigate All Tabs
│   ├── Step 4: Execute Buys
│   ├── Step 5: Verify Portfolio
│   ├── Step 6: Execute Sells
│   ├── Step 7: Data Consistency
│   ├── Step 8: Leaderboard
│   └── Step 9: Profile
│
└── Test 2: With Existing User
    ├── Step 1: Reset Portfolio
    ├── Step 2: Verify Balance
    ├── Step 3: Test Buys
    ├── Step 4: Verify Portfolio
    ├── Step 5: Test Sells
    ├── Step 6: Navigate Features
    ├── Step 7: Pull-to-Refresh
    └── Step 8: Data Consistency
```

---

## Assertions

Each test includes assertions for:

1. **Onboarding Success**
   - Username setup screen appears
   - Button enabled with valid input
   - Main app tab bar appears after completion

2. **Portfolio State**
   - Starting balance = $1,000
   - Cash balance matches expected value
   - Holdings reflect buy/sell operations

3. **Data Consistency**
   - Net worth identical across Home, Portfolio, Profile
   - No discrepancies between screens
   - Values update correctly after transactions

4. **Navigation**
   - All tabs accessible
   - Each tab loads successfully
   - Navigation doesn't cause crashes

5. **Transactions**
   - Buy operations complete successfully
   - Sell operations complete successfully
   - Portfolio updates reflect transactions

6. **Integration**
   - User appears on leaderboard
   - Profile shows correct information
   - All features work together

---

## Debugging

### Verbose Output

Each test prints detailed progress:

```
🎯 COMPLETE END-TO-END TEST: FROM USER CREATION TO ALL FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 STEP 1: Complete Onboarding
──────────────────────────────
📝 Completing onboarding with username: E2ETrader, emoji: 🚀
✅ Username setup screen visible
✅ Start Trading button enabled
🚀 Tapped Start Trading, waiting for user creation...
✅ Successfully reached main app

💰 STEP 2: Verify Initial Portfolio State
──────────────────────────────
💰 Net worth: $1,000.00
✅ Starting balance verified: $1,000
💵 Cash balance: $1,000.00
✅ Cash balance verified: $1,000
```

### Screenshots on Failure

Automatic screenshot capture when any assertion fails:
- Saved to test attachments
- Lifetime: `.keepAlways`
- Includes full screen state

### Test Reporter Integration

Uses `TestReporter.shared` for:
- Test start/end tracking
- Bug reporting on failures
- Assertion counting
- Test metrics

---

## Best Practices

### When to Use Each Test

**Use `testCompleteEndToEndJourneyFromUserCreation` when**:
- Testing the complete new user experience
- Validating onboarding flow changes
- Ensuring first-time users can complete all actions
- Testing end-to-end integration from scratch

**Use `testEndToEndWithExistingUserPortfolioReset` when**:
- Testing feature functionality in isolation
- Validating transaction logic
- Quick smoke tests of main features
- Regression testing without onboarding overhead

### Maintenance

1. **Update timeouts** if network/database operations slow down
2. **Add new features** to both test flows when implemented
3. **Keep helper methods DRY** - avoid duplicating test logic
4. **Update assertions** when business rules change (e.g., starting balance)

### Performance

- Both tests run independently (no shared state)
- Each test resets app state via `RESET_STATE`
- Auto-create user saves ~10 seconds in Test 2
- Portfolio reset is faster than creating new user

---

## Troubleshooting

### Test Times Out During Onboarding

**Symptoms**: Test fails waiting for main app tab bar

**Solutions**:
1. Increase timeout in `completeOnboarding()` (currently 10s)
2. Check Supabase connection
3. Verify network connectivity
4. Try on physical device (simulators can be slow)

### Portfolio Reset Fails

**Symptoms**: Holdings remain after `resetPortfolioToCleanState()`

**Solutions**:
1. Check sell transaction API
2. Verify sell buttons are enabled
3. Increase sleep delays after sell operations
4. Check for modal dialogs blocking sells

### Data Consistency Fails

**Symptoms**: Net worth differs across screens

**Solutions**:
1. Add longer sleep delays between navigation
2. Check for pending transactions
3. Verify pull-to-refresh completes
4. Ensure all screens finish loading

### Leaderboard Empty

**Symptoms**: No entries on leaderboard

**Solutions**:
1. Check leaderboard API endpoint
2. Verify user profile created correctly
3. Increase wait time for leaderboard to load
4. Check network connectivity

---

## Future Enhancements

1. **Parameterized Tests**
   - Test with different starting balances
   - Test with different coin selections
   - Test with various buy/sell amounts

2. **Error Scenarios**
   - Test insufficient funds
   - Test network errors
   - Test invalid inputs

3. **Performance Metrics**
   - Measure transaction completion time
   - Track screen load times
   - Monitor network request duration

4. **Extended Flows**
   - Multi-day portfolio tracking
   - Price change scenarios
   - Leaderboard ranking changes

---

## Integration with CI/CD

### Recommended Setup

```yaml
# Example CI configuration
test:
  script:
    - xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CoinFlipUITests/EndToEndTests

  artifacts:
    when: on_failure
    paths:
      - DerivedData/Logs/Test/*.xcresult

  timeout: 15 minutes
```

### Parallel Execution

Tests can run in parallel on different simulators:
```bash
# Run Test 1 on iPhone 17 Pro
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CoinFlipUITests/EndToEndTests/testCompleteEndToEndJourneyFromUserCreation &

# Run Test 2 on iPhone 15
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CoinFlipUITests/EndToEndTests/testEndToEndWithExistingUserPortfolioReset &

wait
```

---

## Summary

The End-to-End test suite provides comprehensive coverage of the CoinFlip application's critical user journeys. With two complementary test flavors, it ensures both new and existing users can successfully interact with all features while maintaining data consistency throughout the application.

**Key Benefits**:
- Complete user journey validation
- Data consistency verification
- Feature integration testing
- Regression detection
- Documented test flows
- Automated portfolio reset

**Coverage**:
- Onboarding: ✅
- Portfolio Management: ✅
- Buy/Sell Operations: ✅
- Navigation: ✅
- Data Consistency: ✅
- Leaderboard: ✅
- Profile: ✅
- Pull-to-Refresh: ✅
