# Accessibility Identifiers Added

## Summary

All critical accessibility identifiers have been added to enable UI testing.

## Home Screen
- ✅ `netWorthValue` - Net worth display (NetWorthDisplay.swift)
- ✅ `dailyChange` - Daily change percentage (NetWorthDisplay.swift)
- ✅ `buyCoin_{SYMBOL}` - Buy buttons for each coin (CoinCard.swift)
  - e.g., `buyCoin_BTC`, `buyCoin_ETH`, `buyCoin_DOGE`, `buyCoin_XMR`

## Portfolio Screen
- ✅ `portfolioNetWorth` - Net worth (PortfolioView.swift)
- ✅ `portfolioCash` - Cash balance (PortfolioView.swift)
- ✅ `holdingsValue` - Total holdings value (PortfolioView.swift)

## Leaderboard Screen
- ✅ `currentUserRank` - Current user's rank (LeaderboardView.swift)
- ✅ `currentUserNetWorth` - Current user's net worth (LeaderboardView.swift)
- ✅ `currentUserGain` - Current user's total gain % (LeaderboardView.swift)

## Profile Screen
- ✅ `profileUsername` - Username display (UserProfileCard.swift)
- ✅ `profileNetWorth` - Net worth (UserProfileCard.swift)
- ✅ `profileRank` - Leaderboard rank (UserProfileCard.swift)
- ✅ `resetPortfolioButton` - Reset portfolio button (ProfileView.swift)

## Files Modified

1. `/CoinFlip/Components/Display/NetWorthDisplay.swift`
2. `/CoinFlip/Components/Cards/CoinCard.swift`
3. `/CoinFlip/Features/Portfolio/Views/PortfolioView.swift`
4. `/CoinFlip/Features/Profile/Views/ProfileView.swift`
5. `/CoinFlip/Components/Cards/UserProfileCard.swift`
6. `/CoinFlip/Features/Leaderboard/Views/LeaderboardView.swift`

## Note About Cash Balance on Home Screen

The tests expect a `cashBalance` identifier on the Home screen, but the current UI design doesn't display cash balance separately on the Home screen - it only shows net worth. The cash balance is only shown in the Portfolio screen.

**Options:**
1. Update tests to not expect cash balance on Home screen
2. Add a cash balance display component to the Home screen

For now, tests looking for `cashBalance` on Home screen will fail. This is expected given the current UI design.

## Running Tests Now

With these identifiers in place, most tests should now pass. Run:

```bash
cd /Users/avinash/Code/CoinFlip

xcodebuild test \
  -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CoinFlipUITests/DataConsistencyTests/testNetWorthConsistencyAcrossAllScreens
```
