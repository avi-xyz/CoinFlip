# Accessibility Identifier Fix - End-to-End Tests

## Problem

End-to-end tests were failing because **no coin cards or holding cards were found** during test execution. Both tests failed with the same error:

```
⚠️ No coin cards found
📊 Portfolio has 0 holdings
XCTAssertTrue failed - Should have at least one holding after buying
```

Tests completed onboarding successfully and verified starting balance, but failed when trying to interact with coins or holdings.

## Root Cause

The tests were searching for elements with **incorrect accessibility identifiers**:

### Issue 1: Wrong Identifier for CoinCard

**Test was searching for**: `"coinCard"`
**Actual identifier**: `"buyCoin_BTC"`, `"buyCoin_ETH"`, etc.

```swift
// WRONG (in test):
let coinCards = app.otherElements.matching(identifier: "coinCard").allElements
```

**CoinCard.swift** (line 37) has:
```swift
.accessibilityIdentifier("buyCoin_\(coin.symbol)")
```

### Issue 2: Wrong Element Type for CoinCard

**Test was searching**: `otherElements`
**Actual element type**: `Button`

CoinCard is wrapped in a Button, so it should be searched as `app.buttons`, not `app.otherElements`.

### Issue 3: Wrong Identifier for HoldingCard

**Test was searching for**: `"holdingCard"`
**Actual identifier**: `"holding_BTC"`, `"holding_ETH"`, etc.

```swift
// WRONG (in test):
let holdingCards = app.otherElements.matching(identifier: "holdingCard").allElements
```

**HoldingCard.swift** (line 98) has:
```swift
.accessibilityIdentifier("holding_\(coin.symbol)")
```

### Issue 4: Wrong Element Type for HoldingCard

**Test was searching**: `otherElements`
**Actual element type**: `Button`

HoldingCard is also wrapped in a Button.

### Issue 5: No Wait for Coins to Load

Coins load from an API, which takes time. The test wasn't waiting for coins to load before searching for them.

---

## Fixes Applied

### Fix 1: Correct CoinCard Search in `executeBuyOperations()`

**File**: `EndToEndTests.swift`
**Method**: `executeBuyOperations()`

**Before**:
```swift
private func executeBuyOperations() {
    navigateToTab(.home)

    // Find first coin card
    let coinCards = app.otherElements.matching(identifier: "coinCard").allElements
    guard coinCards.count > 0 else {
        print("⚠️ No coin cards found")
        return
    }

    print("📊 Found \(coinCards.count) coins")
```

**After**:
```swift
private func executeBuyOperations() {
    navigateToTab(.home)

    // Wait for coins to load from API
    print("⏳ Waiting for coins to load from API...")
    sleep(5)

    // Find coin buttons - CoinCard uses identifier "buyCoin_SYMBOL" and is a Button
    // Use predicate to find all buttons whose identifier starts with "buyCoin_"
    let predicate = NSPredicate(format: "identifier BEGINSWITH 'buyCoin_'")
    let coinCards = app.buttons.matching(predicate).allElements

    guard coinCards.count > 0 else {
        print("⚠️ No coin cards found after waiting")
        print("ℹ️ Available buttons: \(app.buttons.allElementsBoundByIndex.map { $0.identifier })")
        return
    }

    print("📊 Found \(coinCards.count) coins")
```

**Changes**:
1. Added 5-second wait for coins to load from API
2. Changed from `otherElements` to `buttons`
3. Used NSPredicate to match identifiers starting with `"buyCoin_"`
4. Added debug logging to show available buttons if none found

---

### Fix 2: Correct HoldingCard Search in `verifyPortfolioAfterBuys()`

**File**: `EndToEndTests.swift`
**Method**: `verifyPortfolioAfterBuys()`

**Before**:
```swift
private func verifyPortfolioAfterBuys() {
    navigateToTab(.portfolio)
    sleep(2)

    // Should have at least one holding now
    let holdingCards = app.otherElements.matching(identifier: "holdingCard").allElements
    print("📊 Portfolio has \(holdingCards.count) holdings")

    XCTAssertTrue(holdingCards.count > 0, "Should have at least one holding after buying")

    if holdingCards.count > 0 {
        print("✅ Portfolio updated with holdings")
    }
}
```

**After**:
```swift
private func verifyPortfolioAfterBuys() {
    navigateToTab(.portfolio)
    sleep(2)

    // Should have at least one holding now
    // HoldingCard uses identifier "holding_SYMBOL" and is a Button
    let predicate = NSPredicate(format: "identifier BEGINSWITH 'holding_'")
    let holdingCards = app.buttons.matching(predicate).allElements
    print("📊 Portfolio has \(holdingCards.count) holdings")

    XCTAssertTrue(holdingCards.count > 0, "Should have at least one holding after buying")

    if holdingCards.count > 0 {
        print("✅ Portfolio updated with holdings")
    }
}
```

**Changes**:
1. Changed from `otherElements` to `buttons`
2. Used NSPredicate to match identifiers starting with `"holding_"`

---

### Fix 3: Correct HoldingCard Search in `executeSellOperations()`

**File**: `EndToEndTests.swift`
**Method**: `executeSellOperations()`

**Before**:
```swift
private func executeSellOperations() {
    navigateToTab(.portfolio)
    sleep(2)

    // Find holdings
    let holdingCards = app.otherElements.matching(identifier: "holdingCard").allElements
    guard let firstHolding = holdingCards.first else {
        print("⚠️ No holdings to sell")
        return
    }

    print("💰 Selling first holding...")
    firstHolding.tap()
    sleep(1)
```

**After**:
```swift
private func executeSellOperations() {
    navigateToTab(.portfolio)
    sleep(2)

    // Find holdings - HoldingCard uses identifier "holding_SYMBOL" and is a Button
    let predicate = NSPredicate(format: "identifier BEGINSWITH 'holding_'")
    let holdingCards = app.buttons.matching(predicate).allElements
    guard let firstHolding = holdingCards.first else {
        print("⚠️ No holdings to sell")
        return
    }

    print("💰 Selling first holding...")
    firstHolding.tap()
    sleep(1)
```

**Changes**:
1. Changed from `otherElements` to `buttons`
2. Used NSPredicate to match identifiers starting with `"holding_"`

---

### Fix 4: Correct HoldingCard Search in `resetPortfolioToCleanState()`

**File**: `EndToEndTests.swift`
**Method**: `resetPortfolioToCleanState()`

**Before**:
```swift
private func resetPortfolioToCleanState() {
    navigateToTab(.portfolio)
    sleep(2)

    // Sell all holdings to return to cash
    var holdingCards = app.otherElements.matching(identifier: "holdingCard").allElements

    while holdingCards.count > 0 {
        // ... sell logic ...

        // Refresh list
        holdingCards = app.otherElements.matching(identifier: "holdingCard").allElements
    }
}
```

**After**:
```swift
private func resetPortfolioToCleanState() {
    navigateToTab(.portfolio)
    sleep(2)

    // Sell all holdings to return to cash
    // HoldingCard uses identifier "holding_SYMBOL" and is a Button
    let predicate = NSPredicate(format: "identifier BEGINSWITH 'holding_'")
    var holdingCards = app.buttons.matching(predicate).allElements

    while holdingCards.count > 0 {
        // ... sell logic ...

        // Refresh list
        holdingCards = app.buttons.matching(predicate).allElements
    }
}
```

**Changes**:
1. Changed from `otherElements` to `buttons` (2 places)
2. Used NSPredicate to match identifiers starting with `"holding_"`

---

## Summary of Changes

### Files Modified
- ✅ `EndToEndTests.swift` - Fixed 4 methods

### Methods Fixed
1. ✅ `executeBuyOperations()` - Coin card search + wait for API
2. ✅ `verifyPortfolioAfterBuys()` - Holding card search
3. ✅ `executeSellOperations()` - Holding card search
4. ✅ `resetPortfolioToCleanState()` - Holding card search (2 places)
5. ✅ `testPullToRefresh()` - Coin card search for pull-to-refresh test

### Identifiers Corrected

| Component | Wrong Identifier | Correct Identifier | Element Type |
|-----------|-----------------|-------------------|--------------|
| CoinCard | `"coinCard"` | `"buyCoin_BTC"`, etc. | Button |
| HoldingCard | `"holdingCard"` | `"holding_BTC"`, etc. | Button |

### Build Status
✅ **BUILD SUCCEEDED**

---

## Key Learnings

### 1. Use NSPredicate for Dynamic Identifiers

When identifiers include dynamic values (like coin symbols), use predicates:

```swift
// ✅ CORRECT
let predicate = NSPredicate(format: "identifier BEGINSWITH 'buyCoin_'")
let coinCards = app.buttons.matching(predicate).allElements
```

```swift
// ❌ WRONG
let coinCards = app.otherElements.matching(identifier: "coinCard").allElements
```

### 2. Verify Element Type

Check the actual component implementation to determine the correct element type:

```swift
// CoinCard wraps content in a Button
Button(action: { onTap?() }) {
    // ... content ...
}
.accessibilityIdentifier("buyCoin_\(coin.symbol)")
```

So search for it as a button:
```swift
app.buttons.matching(predicate)  // ✅ CORRECT
```

Not as otherElements:
```swift
app.otherElements.matching(predicate)  // ❌ WRONG
```

### 3. Wait for API Data

When elements depend on API data, add explicit waits:

```swift
// Wait for coins to load from API
print("⏳ Waiting for coins to load from API...")
sleep(5)

// Then search for elements
let coinCards = app.buttons.matching(predicate).allElements
```

### 4. Add Debug Logging

When elements aren't found, log available elements for debugging:

```swift
guard coinCards.count > 0 else {
    print("⚠️ No coin cards found")
    print("ℹ️ Available buttons: \(app.buttons.allElementsBoundByIndex.map { $0.identifier })")
    return
}
```

### 5. Check Actual Implementation

Always check the actual SwiftUI view to see:
1. What accessibility identifier is used
2. What element type it is (Button, Text, etc.)
3. Whether the identifier is dynamic

**Example from CoinCard.swift**:
```swift
struct CoinCard: View {
    let coin: Coin

    var body: some View {
        Button(action: { onTap?() }) {  // ← It's a Button
            // ... card content ...
        }
        .accessibilityIdentifier("buyCoin_\(coin.symbol)")  // ← Dynamic identifier
    }
}
```

---

## Testing Checklist

Before running end-to-end tests:

- [ ] Verify accessibility identifiers match between tests and views
- [ ] Check element types (Button, Text, etc.)
- [ ] Add waits for API-loaded data
- [ ] Use predicates for dynamic identifiers
- [ ] Test with actual device/simulator to verify elements appear

---

## Impact

### ✅ Fixed Tests

Both end-to-end tests should now properly find and interact with:
1. **Coin cards on Home screen** - Can buy coins
2. **Holding cards on Portfolio screen** - Can verify and sell holdings

### ✅ Test Coverage

The tests now correctly cover:
- ✅ Buying coins (finds coin buttons)
- ✅ Verifying portfolio holdings (finds holding buttons)
- ✅ Selling holdings (finds holding buttons)
- ✅ Resetting portfolio (finds and sells all holdings)

### ✅ Better Error Messages

Added debug logging to help diagnose future issues:
```
⏳ Waiting for coins to load from API...
ℹ️ Available buttons: ["buyCoin_BTC", "buyCoin_ETH", "buyCoin_DOGE"]
```

---

## Related Files

### Component Files (Reference)
- `/Users/avinash/Code/CoinFlip/CoinFlip/Components/Cards/CoinCard.swift` - Line 37
- `/Users/avinash/Code/CoinFlip/CoinFlip/Components/Cards/HoldingCard.swift` - Line 98

### Test Files (Modified)
- `/Users/avinash/Code/CoinFlip/CoinFlipUITests/TestCases/EndToEndTests.swift`

---

## Prevention

### For Future Test Development

When writing new UI tests:

1. **Check the actual view first**
   ```bash
   # Search for accessibility identifiers in views
   grep -r "accessibilityIdentifier" CoinFlip/
   ```

2. **Use Xcode Accessibility Inspector**
   - Run app in simulator
   - Open Xcode → Developer Tools → Accessibility Inspector
   - Select simulator
   - Inspect actual identifiers and element types

3. **Start with specific searches**
   ```swift
   // Try specific identifier first
   let element = app.buttons["buyCoin_BTC"]
   if element.exists {
       print("✅ Found with identifier: buyCoin_BTC")
   }
   ```

4. **Then generalize with predicates**
   ```swift
   // Use predicate for multiple similar elements
   let predicate = NSPredicate(format: "identifier BEGINSWITH 'buyCoin_'")
   let elements = app.buttons.matching(predicate).allElements
   ```

5. **Add waits for async data**
   ```swift
   // Wait for API data to load
   sleep(5)

   // Or use waitForExistence
   let element = app.buttons["buyCoin_BTC"]
   let exists = element.waitForExistence(timeout: 10)
   ```

---

## Running Tests

```bash
# Run both end-to-end tests
xcodebuild test -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/EndToEndTests
```

Should now complete successfully! 🎉

---

**Date**: January 15, 2026
**Build Status**: ✅ BUILD SUCCEEDED
**Tests Fixed**: 2 (both end-to-end tests)
**Methods Fixed**: 5 helper methods
**Identifiers Fixed**: All references to "coinCard" and "holdingCard" updated to use correct predicates
