# CoinFlip Tests

This folder contains all tests for the CoinFlip app.

## Test Structure

```
CoinFlipTests/
├── Unit/                 # Unit tests for individual components
│   ├── Services/        # Service layer tests
│   ├── ViewModels/      # ViewModel tests
│   └── Models/          # Model tests
├── Integration/         # Integration tests for workflows
└── UI/                  # UI tests (coming in later sprints)
```

## Running Tests

### In Xcode
1. Press `Cmd + U` to run all tests
2. Or click the diamond icon next to any test function to run individual tests
3. View results in the Test Navigator (`Cmd + 6`)

### Via Command Line
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Coverage

Target: 80%+ code coverage

Current coverage by module:
- SupabaseService: ✅ Covered
- More to come in Sprint 11-18...

## Writing Tests

### Test Naming Convention
- `test<MethodName><Scenario>()` for unit tests
- `testIntegration<Feature><Flow>()` for integration tests
- Use descriptive names that explain what is being tested

### Test Structure (Given-When-Then)
```swift
func testExample() {
    // Given - Set up test conditions
    let sut = SystemUnderTest()

    // When - Perform the action
    let result = sut.doSomething()

    // Then - Assert expectations
    XCTAssertEqual(result, expectedValue)
}
```

### Async Tests
```swift
func testAsyncMethod() async throws {
    // Given
    let sut = SystemUnderTest()

    // When
    let result = await sut.asyncMethod()

    // Then
    XCTAssertNotNil(result)
}
```

## Sprint 11 Tests

### SupabaseServiceTests.swift
Tests for Supabase client initialization and configuration:
- ✅ Singleton pattern
- ✅ Client initialization
- ✅ Configuration validation
- ✅ URL format validation
- ✅ Connection verification
- ✅ Error handling

Run these tests with:
```bash
xcodebuild test -scheme CoinFlip -only-testing:CoinFlipTests/SupabaseServiceTests
```

## Adding New Tests

When adding new test files:
1. Create file in appropriate directory (Unit/Integration/UI)
2. Import `XCTest` and `@testable import CoinFlip`
3. Make class `final` and inherit from `XCTestCase`
4. Add to Xcode project:
   - Right-click CoinFlipTests folder
   - Add Files to "CoinFlip"
   - Select test file
   - Ensure "CoinFlipTests" target is checked

## Test Data

For mock data, use the existing `MockData.swift` in the main app.
For test-specific fixtures, create files in `CoinFlipTests/Fixtures/`

## Troubleshooting

### Tests not appearing in Xcode
- Make sure files are added to the CoinFlipTests target
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

### Tests failing on CI
- Check for hardcoded paths or dates
- Ensure tests are deterministic (not time-dependent)
- Use mocks for external dependencies

### Async test timeouts
- Increase timeout: `await fulfillment(of: [expectation], timeout: 10)`
- Check for deadlocks or infinite loops

## Next Steps

Sprint 11 will add more tests for:
- Database models (User, Portfolio, Holdings, Transactions)
- Data service layer (Real vs Mock implementation)
- Authentication service (Passkey integration)
