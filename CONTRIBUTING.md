# Contributing to CoinFlip

Thank you for your interest in contributing to CoinFlip! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the problem
- **Expected behavior** vs **actual behavior**
- **Screenshots** if applicable
- **Environment details**: iOS version, device model, Xcode version

### Suggesting Enhancements

Enhancement suggestions are welcome! Include:

- **Use case**: Why would this be useful?
- **Proposed solution**: How should it work?
- **Alternatives considered**: What other approaches did you think about?

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Write clean, documented code
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Test your changes**:
   ```bash
   # Run unit tests
   xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

   # Run UI tests
   xcodebuild test -scheme CoinFlip -only-testing:CoinFlipUITests
   ```

5. **Commit** with clear messages:
   ```bash
   git commit -m "Add feature: brief description

   Detailed explanation of what changed and why."
   ```

6. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request** with:
   - Clear title describing the change
   - Description of what was changed and why
   - Link to related issues
   - Screenshots/videos if UI changes

## Development Setup

### Prerequisites

- macOS 14.0+
- Xcode 16.0+
- CocoaPods or Swift Package Manager
- Supabase account (for backend features)

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/CoinFlip.git
   cd CoinFlip
   ```

2. Open in Xcode:
   ```bash
   open CoinFlip.xcodeproj
   ```

3. Configure Supabase:
   - Create a Supabase project
   - Update `SupabaseService.swift` with your credentials
   - Run database migrations (see `docs/database-schema.sql`)

4. Build and run:
   - Select a simulator or device
   - Press `Cmd+R`

## Code Style

### Swift Style Guide

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

```swift
// ✅ Good
func fetchTrendingCoins(limit: Int) async throws -> [Coin] {
    // Implementation
}

// ❌ Bad
func fetch_trending_coins(limit: Int) async throws -> [Coin] {
    // Implementation
}
```

### SwiftUI Best Practices

- Keep views small and focused
- Extract complex views into components
- Use `@State` for view-local state
- Use `@StateObject` for view-owned objects
- Use `@ObservedObject` for passed-in objects
- Use `@EnvironmentObject` for app-wide shared state

```swift
// ✅ Good: Small, focused view
struct CoinCard: View {
    let coin: Coin
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CoinCardContent(coin: coin)
        }
    }
}

// ❌ Bad: Too much logic in view
struct CoinCard: View {
    let coin: Coin
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        // 100+ lines of code...
    }
}
```

### MVVM Architecture

- Views display UI
- ViewModels handle business logic
- Models represent data
- Services handle API/database calls

```
Feature/
├── Views/
│   └── FeatureView.swift
├── ViewModels/
│   └── FeatureViewModel.swift
└── Models/
    └── FeatureModel.swift
```

### Comments and Documentation

```swift
/// Fetches trending meme coins from CoinGecko API
///
/// - Parameter limit: Maximum number of coins to return
/// - Returns: Array of trending coins with current prices
/// - Throws: `APIError` if network request fails
func fetchTrendingCoins(limit: Int) async throws -> [Coin] {
    // Implementation
}
```

## Testing Guidelines

### Unit Tests

- Test business logic in ViewModels
- Mock external dependencies
- Aim for >70% code coverage

```swift
func testBuyingCoin() {
    // Given
    let portfolio = Portfolio(userId: UUID(), startingBalance: 1000)
    let coin = Coin(id: "bitcoin", symbol: "BTC", currentPrice: 100)

    // When
    let transaction = portfolio.buy(coin: coin, amount: 500)

    // Then
    XCTAssertNotNil(transaction)
    XCTAssertEqual(portfolio.cashBalance, 500)
}
```

### UI Tests

- Test critical user flows
- Use Page Object pattern
- Add accessibility identifiers

```swift
func testBuyFlow() {
    let app = XCUIApplication()
    app.launch()

    // Navigate to buy screen
    app.buttons["buyCoin_BTC"].tap()

    // Enter amount and confirm
    app.buttons["confirmBuyButton"].tap()

    // Verify success
    XCTAssertTrue(app.alerts["Success"].exists)
}
```

## Project Structure

```
CoinFlip/
├── App/                      # App entry point
├── Features/                 # Feature modules
│   ├── Home/
│   ├── Portfolio/
│   ├── Trading/
│   ├── Leaderboard/
│   └── Profile/
├── Models/                   # Data models
├── Services/                 # API/Database services
├── Components/               # Reusable UI components
├── Core/                     # Core utilities
│   ├── Theme/
│   ├── Extensions/
│   └── Utilities/
└── Assets.xcassets/         # Images, colors, etc.
```

## Adding New Features

### 1. Create Feature Branch

```bash
git checkout -b feature/new-feature
```

### 2. Create Feature Module

```
Features/NewFeature/
├── Views/
│   └── NewFeatureView.swift
├── ViewModels/
│   └── NewFeatureViewModel.swift
└── Models/
    └── NewFeature.swift
```

### 3. Add Tests

```swift
// NewFeatureViewModelTests.swift
@testable import CoinFlip
import XCTest

final class NewFeatureViewModelTests: XCTestCase {
    // Test cases
}
```

### 4. Update Documentation

- Update README.md with new feature
- Add inline code comments
- Create usage examples

### 5. Submit PR

- Ensure all tests pass
- Update CHANGELOG.md
- Request review

## Common Tasks

### Adding a New Coin Type

1. Update `Coin` model if needed
2. Update `CryptoAPIService` to fetch the coin
3. Add UI support in `CoinCard`
4. Test with real API data

### Adding a New Screen

1. Create in `Features/` directory
2. Add ViewModel if needed
3. Add navigation from existing screen
4. Add accessibility identifiers
5. Write UI tests

### Updating Database Schema

1. Update models in `Models/`
2. Update database schema in Supabase
3. Update `DataServiceProtocol`
4. Update `SupabaseDataService`
5. Test with real database

## Release Process

1. Version bump in Xcode project
2. Update CHANGELOG.md
3. Tag release: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. Create GitHub release with notes

## Getting Help

- **Questions?** Open a discussion on GitHub
- **Bug?** Create an issue with reproduction steps
- **Feature idea?** Open an issue with proposal

## Recognition

Contributors will be added to:
- README.md Contributors section
- Release notes
- App credits (for significant contributions)

---

Thank you for contributing to CoinFlip! 🚀
