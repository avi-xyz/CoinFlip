# Onboarding Test Setup Guide

## Problem
All tests were failing because the app requires users to complete onboarding (create username + select avatar) before accessing the main app. Tests were getting stuck on the username setup screen.

## Solution

We've implemented **two complementary approaches**:

### Approach 1: Auto-Create Test User (for existing tests)
Automatically creates a test user on app launch, bypassing the onboarding flow.

### Approach 2: Test Onboarding Flow (for onboarding-specific tests)
Comprehensive tests for the actual user journey from first launch to main app.

---

## Setup Instructions

### Step 1: Add New Files to Xcode Project

The following files were created but need to be added to the Xcode project target:

1. **Page Objects:**
   - `CoinFlipUITests/PageObjects/UsernameSetupScreen.swift`
   - `CoinFlipUITests/PageObjects/OnboardingScreen.swift`

2. **Test Cases:**
   - `CoinFlipUITests/TestCases/OnboardingTests.swift`

**To add them:**
1. Open Xcode
2. Right-click on `CoinFlipUITests/PageObjects` folder
3. Select "Add Files to CoinFlip..."
4. Navigate to and select:
   - `UsernameSetupScreen.swift`
   - `OnboardingScreen.swift`
5. Make sure "CoinFlipUITests" target is checked
6. Click "Add"

7. Repeat for `CoinFlipUITests/TestCases`:
   - `OnboardingTests.swift`

### Step 2: Verify Build

```bash
xcodebuild -scheme CoinFlip -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## How It Works

### Auto-Create Test User

**Modified Files:**
- `CoinFlip/Features/Auth/Views/UsernameSetupView.swift`
  - Added `.onAppear` check for `AUTO_CREATE_TEST_USER` environment variable
  - Automatically fills in username "TestUser" and emoji "🚀"
  - Triggers profile creation after 0.5s delay

- `CoinFlipUITests/Helpers/UITestBase.swift`
  - Added `AUTO_CREATE_TEST_USER: "1"` to launch environment
  - Increased wait timeout to 30 seconds for user creation
  - Added diagnostic logging

**What happens:**
1. Test launches app with `AUTO_CREATE_TEST_USER=1`
2. App goes through normal flow: anonymous sign-in → username setup screen
3. Username setup screen detects environment variable
4. Automatically fills username and avatar
5. Calls `createProfile()` which:
   - Creates user in database
   - Creates portfolio with $1,000 starting balance
   - Transitions to main app
6. Test continues once tab bar appears

### Manual Onboarding Helper

For tests that need to test different usernames or scenarios:

```swift
// In your test
override func setUpWithError() throws {
    // ... setup without AUTO_CREATE_TEST_USER ...

    // Manually complete onboarding with custom username
    let success = completeOnboardingManually(username: "CustomUser", emoji: "💎")
    XCTAssertTrue(success, "Onboarding should complete successfully")
}
```

---

## Running Tests

### Run All Tests (with auto-create user)
```bash
xcodebuild test -scheme CoinFlip \\
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \\
  -only-testing:CoinFlipUITests
```

### Run Onboarding Tests (manual flow)
```bash
xcodebuild test -scheme CoinFlip \\
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \\
  -only-testing:CoinFlipUITests/OnboardingTests
```

### Run Single Test
```bash
xcodebuild test -scheme CoinFlip \\
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \\
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
```

---

## Test Categories

### 1. Onboarding Tests (`OnboardingTests.swift`)
Tests the complete user journey from first launch:
- `testCompleteOnboardingJourneyWithValidUsername()` - Full flow from username to main app
- `testInvalidUsernameValidation()` - Username validation rules
- `testAvatarSelection()` - Avatar picker functionality
- `testUsernameSetupUIElements()` - UI elements presence
- `testStartingBalanceAfterOnboarding()` - Verify $1,000 starting balance

These tests **DO NOT use auto-create** - they test the actual manual flow.

### 2. Data Consistency Tests (`DataConsistencyTests.swift`)
- Net worth consistency across all screens
- Cash balance consistency
- Buy/sell operation data integrity

These tests **use auto-create** for fast execution.

### 3. Feature Tests (HomeScreenTests, PortfolioScreenTests, etc.)
- Buy/sell operations
- Navigation
- UI interactions
- Pull-to-refresh

These tests **use auto-create** for fast execution.

---

## Troubleshooting

### Tests Still Failing with "Username Setup Screen Visible"

**Symptoms:**
- Test output shows: "Still on username setup screen - auto-create failed!"
- Tests timeout waiting for tab bar

**Possible Causes:**
1. Environment variable not being passed correctly
2. User creation API call failing
3. Network/database connectivity issues

**Diagnostics:**
```swift
// In UITestBase.setUpWithError(), check the output
if !tabBarAppeared {
    let usernameField = app.textFields["usernameTextField"]
    if usernameField.exists {
        print("❌ Still on username setup screen - auto-create failed!")
        // Take screenshot to see what's on screen
    }
}
```

**Solutions:**
- Check Supabase connection is working
- Verify `RESET_STATE` is properly resetting database
- Try increasing wait timeout beyond 30 seconds
- Run with manual onboarding instead

### Onboarding Tests Fail to Find Elements

**Symptoms:**
- OnboardingTests can't find username field or buttons

**Solution:**
- Verify accessibility identifiers were added to `UsernameSetupView.swift`
- Check the identifiers match what's in `UsernameSetupScreen.swift` page object

### Build Errors about Missing Classes

**Symptoms:**
- "Cannot find 'UsernameSetupScreen' in scope"

**Solution:**
- Add the new page object files to Xcode project target (see Step 1 above)
- Make sure they're added to `CoinFlipUITests` target, not `CoinFlip` target

---

## Modified Files Summary

### App Code (Modified)
1. `CoinFlip/Features/Auth/Views/UsernameSetupView.swift`
   - Added auto-create functionality
   - Added accessibility identifiers

### Test Infrastructure (Modified)
1. `CoinFlipUITests/Helpers/UITestBase.swift`
   - Added `AUTO_CREATE_TEST_USER` environment variable
   - Increased timeout for user creation
   - Added `completeOnboardingManually()` helper method

### Test Infrastructure (New)
1. `CoinFlipUITests/PageObjects/UsernameSetupScreen.swift`
2. `CoinFlipUITests/PageObjects/OnboardingScreen.swift`
3. `CoinFlipUITests/TestCases/OnboardingTests.swift`

---

## Best Practices

### When to Use Auto-Create vs Manual Onboarding

**Use Auto-Create (default):**
- Testing app features (buy/sell, portfolio, leaderboard)
- Data consistency tests
- Navigation tests
- Performance tests (faster execution)

**Use Manual Onboarding:**
- Testing the onboarding flow itself
- Testing username validation
- Testing avatar selection
- Testing first-time user experience

### Writing New Tests

```swift
// For feature tests (use auto-create - default)
final class MyFeatureTests: UITestBase {
    // UITestBase already has AUTO_CREATE_TEST_USER enabled
    // Just write your test!

    func testMyFeature() {
        // App is already at main screen with TestUser created
        homeScreen.buyCoin(symbol: "BTC", amount: "100")
        // ...
    }
}

// For onboarding tests (disable auto-create)
final class MyOnboardingTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launchEnvironment = ["RESET_STATE": "1"]  // NO auto-create
        app.launch()

        // Manually test onboarding flow
    }
}
```

---

## Future Improvements

1. **Parallel Test Execution:**
   - Each test currently creates a new user
   - Could optimize by sharing a user across tests
   - Need to handle state cleanup between tests

2. **Test Data Management:**
   - Consider creating different test users with different states
   - E.g., "EmptyPortfolioUser", "RichUser", "NewTraderUser"

3. **Environment Flags:**
   - Add more flags like `SKIP_ONBOARDING_TUTORIAL`
   - Add `USE_MOCK_DATA` for offline testing
   - Add `FAST_MODE` to skip animations/delays

4. **Database Seeding:**
   - Pre-populate database with test users
   - Faster than creating new user each time
   - Need cleanup strategy

---

## End-to-End Test Suite

**New comprehensive test suite added**: `EndToEndTests.swift`

This test suite provides complete user journey testing with two flavors:

### 1. Complete Journey from User Creation
- Tests full flow from onboarding to all features
- Validates new user experience
- See: `testCompleteEndToEndJourneyFromUserCreation()`

### 2. Journey with Existing User + Portfolio Reset
- Auto-creates user for faster execution
- Resets portfolio to clean state
- Tests all features with established user
- See: `testEndToEndWithExistingUserPortfolioReset()`

**Coverage**:
- ✅ Onboarding flow
- ✅ Buy/sell operations
- ✅ Portfolio management
- ✅ Data consistency across screens
- ✅ Navigation through all tabs
- ✅ Leaderboard integration
- ✅ Profile information
- ✅ Pull-to-refresh

**Documentation**: See `END_TO_END_TESTS.md` for complete details.

**Run All End-to-End Tests**:
```bash
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests
```

---

## Questions?

If tests are still failing after following this guide:
1. Check the console output for diagnostic messages
2. Look for the specific error in UITestBase setup
3. Verify all files are added to Xcode project
4. Ensure accessibility identifiers exist in the app code
5. Try running OnboardingTests first to verify manual flow works
