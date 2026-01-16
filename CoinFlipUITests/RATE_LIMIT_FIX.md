# Supabase Rate Limit Fix for UI Tests

## Problem

UI tests were failing due to Supabase rate limiting errors. Each test run creates a new anonymous user, and running multiple tests quickly hits Supabase's authentication rate limits.

## Solutions Implemented

### 1. Retry Logic with Exponential Backoff (AuthService.swift)

**File**: `CoinFlip/Services/AuthService.swift`

Added automatic retry logic to `signInAnonymously()` method:

```swift
// Retry logic with exponential backoff for rate limiting
var retryCount = 0
let maxRetries = 3
var lastError: Error?

while retryCount < maxRetries {
    do {
        let session = try await supabase.auth.signInAnonymously()
        // Success!
        return
    } catch {
        // Check if it's a rate limit error (429, "rate", "limit")
        if errorDescription.contains("rate") || errorDescription.contains("limit") {
            retryCount += 1
            let delay = Double(retryCount * retryCount) * 2.0 // 2s, 8s, 18s

            if retryCount < maxRetries {
                print("⚠️ Rate limit hit, retrying in \(delay)s...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
        }
    }
}
```

**How it works:**
- Detects rate limit errors by checking error messages for "rate", "limit", or HTTP 429
- Retries up to 3 times with exponential backoff (2s → 8s → 18s)
- Throws error if max retries reached or non-rate-limit error occurs

### 2. Delay Before Auto Sign-In (AuthService.swift)

**File**: `CoinFlip/Services/AuthService.swift`, line 203

Added 1-second delay in `checkSession()` before attempting anonymous sign-in:

```swift
// Add a small delay before auto sign in to avoid immediate rate limiting
try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

// Auto sign in anonymously (with retry logic)
try await signInAnonymously()
```

**Why:** Prevents rapid-fire authentication requests when app launches.

### 3. Increased Test Setup Delays (EndToEndTests.swift)

**File**: `CoinFlipUITests/TestCases/EndToEndTests.swift`

#### Setup Delay (line 192)
Changed from `sleep(2)` to `sleep(5)`:

```swift
app.launch()
sleep(5)  // Allow reset to complete + rate limit cooldown
```

#### Teardown Delay (line 171)
Changed from `sleep(1)` to `sleep(5)`:

```swift
app?.terminate()
sleep(5)  // Longer delay between tests to avoid rate limiting
```

**Why:** Spaces out authentication requests between test runs, giving Supabase time to reset rate limits.

## Expected Behavior

### Before Fix
```
🔐 AuthService: Attempting anonymous sign in...
❌ AuthService: Anonymous sign in failed - Rate limit exceeded
Test failed: Authentication error
```

### After Fix
```
🔐 AuthService: Attempting anonymous sign in...
⚠️ AuthService: Rate limit hit, retrying in 2.0s (attempt 1/3)...
🔐 AuthService: Attempting anonymous sign in...
✅ AuthService: Anonymous sign in successful
```

## Benefits

1. **Automatic Recovery** - Tests automatically retry on rate limit errors
2. **Exponential Backoff** - Increasing delays prevent hammering the API
3. **Better Test Spacing** - Longer delays between tests reduce overall rate limit pressure
4. **Clear Logging** - Console output shows retry attempts and delays

## Additional Recommendations

### For Local Development

If you're running tests frequently during development, consider these additional options:

#### 1. Increase Delays Further (If Still Hitting Limits)

In `EndToEndTests.swift`, increase delays:

```swift
sleep(10)  // Instead of 5 seconds
```

#### 2. Run Tests Individually

Instead of running all tests at once:

```bash
# Run one test at a time
xcodebuild test -only-testing:CoinFlipUITests/EndToEndTests/testCompleteEndToEndJourneyFromUserCreation
```

#### 3. Add Delay Between Test Commands

If running multiple test commands, add delays:

```bash
xcodebuild test -only-testing:CoinFlipUITests/EndToEndTests/testCompleteEndToEndJourneyFromUserCreation
sleep 10
xcodebuild test -only-testing:CoinFlipUITests/EndToEndTests/testAnotherTest
```

### For CI/CD

#### 1. Space Out Test Jobs

Configure CI to run UI tests with delays between jobs:

```yaml
# GitHub Actions example
- name: Run UI Tests
  run: |
    xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CoinFlipUITests/EndToEndTests

- name: Wait before next test suite
  run: sleep 30
```

#### 2. Limit Concurrent Test Runs

Ensure only one test suite runs at a time to avoid overwhelming Supabase.

### For Production (Long-term Solutions)

#### 1. Mock Authentication for Tests

Create a mock auth service that doesn't hit Supabase:

```swift
// In test environment
if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
    // Use mock auth service that doesn't call Supabase
}
```

#### 2. Reuse Test Users

Instead of creating new users each time, maintain a pool of test users:

```swift
// Check for existing test user first
if let existingUser = try? await findTestUser("E2ETrader") {
    // Reuse existing user
} else {
    // Create new user only if needed
}
```

#### 3. Local Supabase Instance

Set up a local Supabase instance for testing:

```bash
# Using Supabase CLI
supabase start
```

Update test environment to use local instance:

```swift
app.launchEnvironment = [
    "SUPABASE_URL": "http://localhost:54321",
    "RESET_STATE": "1"
]
```

#### 4. Upgrade Supabase Plan

If rate limits are consistently an issue, consider upgrading your Supabase plan for higher rate limits.

## Testing the Fix

Run the end-to-end tests to verify rate limiting is handled:

```bash
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests
```

Watch for retry messages in console:

```
⚠️ AuthService: Rate limit hit, retrying in 2.0s (attempt 1/3)...
⚠️ AuthService: Rate limit hit, retrying in 8.0s (attempt 2/3)...
✅ AuthService: Anonymous sign in successful
```

## Monitoring

Keep an eye on:

1. **Test execution time** - Retries and delays will increase test duration
2. **Success rate** - Tests should now pass even with rate limiting
3. **Retry frequency** - If seeing retries on every test, consider increasing delays further

## Reverting Changes (If Needed)

If these changes cause issues:

1. **Reduce delays** in `EndToEndTests.swift` back to original values
2. **Remove retry logic** from `AuthService.swift` (restore from git)
3. **Consider alternative approaches** listed in "Long-term Solutions" section

---

**Last Updated**: January 16, 2026
**Build Status**: ✅ BUILD SUCCEEDED
**Issue**: Supabase rate limiting during UI tests
**Solution**: Retry logic with exponential backoff + increased test delays
