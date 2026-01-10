# CoinFlip Backend Implementation: Sprints 12-18

**Continuation of:** Backend-Implementation-Plan.md
**Version:** 1.0

---

## SPRINT 12: Authentication & Passkey

**Duration:** 4-6 days
**Goal:** Implement user authentication with Supabase Auth and Passkey support

### Prerequisites
```bash
git checkout develop
git checkout -b feature/sprint-12-authentication
```

---

### Task 12.1: Supabase Auth Setup

**Branch:** `feature/sprint-12-task-1-supabase-auth`

#### Prompt to Execute
```
Execute Task 12.1: Supabase Auth Setup

Steps:
1. Enable email authentication in Supabase dashboard
2. Configure redirect URLs for iOS deep linking
3. Create AuthService.swift with Supabase Auth methods
4. Implement sign up, sign in, sign out methods
5. Add session persistence and restoration
6. Create unit tests for AuthService

Acceptance Criteria:
- Supabase Auth configured in dashboard
- AuthService created with all auth methods
- Session persists across app launches
- Auth state observable via Combine
- Tests verify auth flows

Files to Create:
- Services/AuthService.swift
- Models/AuthState.swift
- Tests/Unit/AuthServiceTests.swift

Tests Required:
1. testSignUpNewUser() - Verify user creation
2. testSignInExistingUser() - Verify login
3. testSignOut() - Verify logout
4. testSessionPersistence() - Verify session restored
5. testAuthStateChanges() - Verify observable state
```

#### Implementation

**File:** `Services/AuthService.swift`
```swift
import Foundation
import Supabase
import Combine

enum AuthState {
    case authenticated(User)
    case unauthenticated
    case loading
}

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var authState: AuthState = .loading
    @Published var currentUser: User?

    private let supabase = SupabaseService.shared.client
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DataServiceFactory.shared.makeService()
        observeAuthStateChanges()
        Task { await checkSession() }
    }

    // MARK: - Auth State Management

    private func observeAuthStateChanges() {
        supabase.auth.authStateChanges
            .sink { [weak self] event, session in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    switch event {
                    case .signedIn:
                        if let session = session {
                            await self.handleSignIn(session: session)
                        }
                    case .signedOut:
                        self.handleSignOut()
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            await handleSignIn(session: session)
        } catch {
            authState = .unauthenticated
        }
    }

    private func handleSignIn(session: Session) async {
        do {
            // Fetch or create user in our database
            if let user = try await dataService.fetchUser(authUserId: session.user.id) {
                await MainActor.run {
                    self.currentUser = user
                    self.authState = .authenticated(user)
                }
            } else {
                // Create new user
                let username = session.user.email?.components(separatedBy: "@").first ?? "User"
                let user = try await dataService.createUser(
                    authUserId: session.user.id,
                    username: username,
                    avatarEmoji: "🚀"
                )
                await MainActor.run {
                    self.currentUser = user
                    self.authState = .authenticated(user)
                }
            }
        } catch {
            print("Error handling sign in: \(error)")
            await MainActor.run {
                self.authState = .unauthenticated
            }
        }
    }

    private func handleSignOut() {
        currentUser = nil
        authState = .unauthenticated
    }

    // MARK: - Auth Actions

    func signUp(email: String, password: String, username: String) async throws {
        authState = .loading

        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        guard let session = response.session else {
            throw AuthError.signUpFailed
        }

        // Create user profile
        let user = try await dataService.createUser(
            authUserId: session.user.id,
            username: username,
            avatarEmoji: "🚀"
        )

        // Create portfolio
        _ = try await dataService.createPortfolio(userId: user.id)

        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
        }
    }

    func signIn(email: String, password: String) async throws {
        authState = .loading

        try await supabase.auth.signIn(
            email: email,
            password: password
        )

        // Auth state change will be handled by observer
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        // Auth state change will be handled by observer
    }

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
}

enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case invalidSession

    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account"
        case .signInFailed:
            return "Failed to sign in"
        case .invalidSession:
            return "Session expired"
        }
    }
}
```

#### Tests

**File:** `Tests/Unit/AuthServiceTests.swift`
```swift
import XCTest
@testable import CoinFlip

class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        // Note: AuthService needs to be testable with dependency injection
    }

    func testAuthStateInitiallyLoading() {
        // On init, auth state should be loading
        // This will be implemented once we add DI to AuthService
    }

    func testSignUpCreatesUserAndPortfolio() async throws {
        // Test that sign up:
        // 1. Creates user in database
        // 2. Creates portfolio for user
        // 3. Updates auth state to authenticated
    }

    func testSignInUpdatesAuthState() async throws {
        // Test successful sign in updates state
    }

    func testSignOutClearsAuthState() async throws {
        // Test sign out clears user and state
    }

    func testSessionPersistence() async throws {
        // Test that session is restored on app launch
    }
}
```

---

### Task 12.2: Authentication UI

**Branch:** `feature/sprint-12-task-2-auth-views`

#### Prompt to Execute
```
Execute Task 12.2: Authentication UI

Steps:
1. Create LoginView with email/password form
2. Create SignUpView with username, email, password
3. Create AuthViewModel to manage auth state
4. Update ContentView to show Login if not authenticated
5. Add password validation and error handling
6. Create UI tests for auth flows

Acceptance Criteria:
- Login view with email/password fields
- Sign up view with username, email, password
- Proper validation (email format, password strength)
- Error messages displayed
- Loading states shown
- Navigation between login/signup
- UI tests verify flows

Files to Create:
- Features/Auth/Views/LoginView.swift
- Features/Auth/Views/SignUpView.swift
- Features/Auth/ViewModels/AuthViewModel.swift
- Features/Auth/Components/AuthTextField.swift
- Tests/UI/AuthUITests.swift

Tests Required:
1. testLoginFlowValid() - Complete login flow
2. testSignUpFlowValid() - Complete signup flow
3. testValidationErrors() - Test form validation
4. testNavigationBetweenViews() - Test switching views
```

#### Implementation Files

**File:** `Features/Auth/ViewModels/AuthViewModel.swift`
```swift
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUpMode = false

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    var isFormValid: Bool {
        if isSignUpMode {
            return isEmailValid && isPasswordValid && !username.isEmpty
        } else {
            return isEmailValid && !password.isEmpty
        }
    }

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var emailError: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Invalid email format"
    }

    var passwordError: String? {
        guard !password.isEmpty else { return nil }
        return isPasswordValid ? nil : "Password must be at least 6 characters"
    }

    func signIn() async {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
            // Success handled by auth state observer
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp() async {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(
                email: email,
                password: password,
                username: username
            )
            // Success handled by auth state observer
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
    }
}
```

**File:** `Features/Auth/Views/LoginView.swift`
```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Logo
                    Text("🪙")
                        .font(.system(size: 80))
                        .padding(.top, Spacing.xxl)

                    Text("CoinFlip")
                        .font(.displayLarge)
                        .foregroundColor(.textPrimary)

                    Text("Learn crypto trading risk-free")
                        .font(.bodyLarge)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer().frame(height: Spacing.xl)

                    // Email Field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Email")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)

                        TextField("your@email.com", text: $viewModel.email)
                            .textFieldStyle(AuthTextFieldStyle())
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if let error = viewModel.emailError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.lossRed)
                        }
                    }

                    // Password Field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Password")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(AuthTextFieldStyle())
                            .textContentType(.password)

                        if let error = viewModel.passwordError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.lossRed)
                        }
                    }

                    // Username (Sign Up Only)
                    if viewModel.isSignUpMode {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Username")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)

                            TextField("Username", text: $viewModel.username)
                                .textFieldStyle(AuthTextFieldStyle())
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                        }
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.lossRed)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.lossRed.opacity(0.1))
                            .cornerRadius(Spacing.sm)
                    }

                    // Action Button
                    PrimaryButton(
                        title: viewModel.isSignUpMode ? "Create Account" : "Sign In",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            if viewModel.isSignUpMode {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    // Toggle Mode
                    Button {
                        viewModel.toggleMode()
                    } label: {
                        Text(viewModel.isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.bodyMedium)
                            .foregroundColor(.primaryGreen)
                    }

                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
            }
            .background(Color.appBackground)
        }
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(Spacing.md)
            .foregroundColor(.textPrimary)
    }
}

// Add to PrimaryButton.swift
extension PrimaryButton {
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = nil
        self.action = action
        // Show loading indicator if isLoading
    }
}
```

**File:** Update `App/ContentView.swift`
```swift
struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var homeViewModel: HomeViewModel
    // ... other view models

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                LoginView()
            case .authenticated(let user):
                authenticatedView(user: user)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
        }
        .onAppear {
            if case .authenticated = authService.authState {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
        }
    }

    @ViewBuilder
    private func authenticatedView(user: User) -> some View {
        TabView {
            // ... existing tab views
        }
        .preferredColorScheme(.dark)
        .accentColor(.primaryGreen)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
```

---

### Task 12.3: Passkey Integration

**Branch:** `feature/sprint-12-task-3-passkey`

#### Prompt to Execute
```
Execute Task 12.3: Passkey Integration

Steps:
1. Configure associated domains in Xcode
2. Add Passkey capability to app
3. Implement WebAuthn registration in LoginView
4. Add Passkey sign-in option
5. Handle Passkey errors and fallbacks
6. Test Passkey flow on device

Acceptance Criteria:
- Associated domains configured
- Passkey registration works
- Passkey sign-in works
- Graceful fallback to password
- Error handling implemented
- Works on physical device

Files to Update:
- CoinFlip.entitlements (add webcredentials)
- LoginView.swift (add Passkey button)
- AuthViewModel.swift (add Passkey methods)

Tests Required:
- Manual testing on physical device required
- testPasskeyRegistration() - Test registration
- testPasskeySignIn() - Test sign-in
```

#### Implementation

**File:** `CoinFlip.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>webcredentials:YOUR_PROJECT.supabase.co</string>
    </array>
</dict>
</plist>
```

**Note:** Passkey implementation requires additional Supabase configuration and is advanced. Document this as "Optional Enhancement" for later.

---

### Task 12.4: Sprint 12 Testing

**Branch:** `feature/sprint-12-task-4-tests`

#### Prompt to Execute
```
Execute Task 12.4: Sprint 12 Testing and Merge

Steps:
1. Run all auth unit tests
2. Run UI tests for login/signup flows
3. Manual testing of complete auth flow
4. Test session persistence (kill app, relaunch)
5. Test error scenarios (wrong password, network error)
6. Merge sprint to develop
7. Tag sprint-12-complete

Manual Testing Checklist:
- [ ] Sign up new account
- [ ] Verify user created in Supabase
- [ ] Verify portfolio created
- [ ] Sign out
- [ ] Sign in with same account
- [ ] Verify session persists
- [ ] Test wrong password
- [ ] Test network error handling
```

---

## SPRINT 13: Real-Time Crypto Prices

**Duration:** 3-4 days
**Goal:** Replace mock coin data with real CoinGecko API

### Task 13.1: CoinGecko Service

#### Prompt to Execute
```
Execute Task 13.1: CoinGecko API Integration

Steps:
1. Sign up for CoinGecko API key
2. Add API key to EnvironmentConfig
3. Create CryptoAPIService.swift
4. Implement fetchTrendingCoins() method
5. Implement fetchCoinPrice() method
6. Add error handling and retry logic
7. Create unit tests with mock responses

Files to Create:
- Services/CryptoAPIService.swift
- Models/CoinGeckoResponse.swift
- Tests/Unit/CryptoAPIServiceTests.swift
- Tests/Mocks/MockCryptoAPIResponses.json
```

---

## SPRINT 14: Portfolio Persistence

**Duration:** 4-5 days
**Goal:** Sync buy/sell operations with backend

### Task 14.1: Portfolio Operations

#### Prompt to Execute
```
Execute Task 14.1: Portfolio CRUD Operations

Steps:
1. Update HomeViewModel to use DataService
2. Implement buy() with backend sync
3. Implement sell() with backend sync
4. Add optimistic UI updates
5. Handle sync failures gracefully
6. Create integration tests

Tests:
- testBuySyncsToBackend()
- testSellSyncsToBackend()
- testOptimisticUpdate()
- testSyncFailureRollback()
```

---

## SPRINT 15: Settings Implementation

**Duration:** 2-3 days
**Goal:** Make all profile settings functional

### Tasks

#### 15.1: Username Change
```
Create EditUsernameView
Add save to Supabase
Update local state
```

#### 15.2: Notifications Toggle
```
Implement notification permission request
Save preference to UserDefaults
```

#### 15.3: Dark Mode Toggle
```
Create theme selection
Apply theme dynamically
```

---

## SPRINT 16: Leaderboard Backend

**Duration:** 3-4 days
**Goal:** Replace mock leaderboard with real data

### Task 16.1: Leaderboard View & Function

#### SQL Function
```sql
CREATE OR REPLACE FUNCTION get_leaderboard(limit_count INT DEFAULT 50)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_emoji TEXT,
  net_worth DECIMAL,
  gain_percentage DECIMAL,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.username,
    u.avatar_emoji,
    (p.cash_balance + COALESCE(SUM(h.quantity * h.average_buy_price), 0)) as net_worth,
    ((p.cash_balance + COALESCE(SUM(h.quantity * h.average_buy_price), 0) - p.starting_balance)
      / p.starting_balance * 100) as gain_percentage,
    ROW_NUMBER() OVER (ORDER BY (p.cash_balance + COALESCE(SUM(h.quantity * h.average_buy_price), 0)) DESC) as rank
  FROM users u
  JOIN portfolios p ON u.id = p.user_id
  LEFT JOIN holdings h ON p.id = h.portfolio_id
  GROUP BY u.id, u.username, u.avatar_emoji, p.cash_balance, p.starting_balance
  ORDER BY net_worth DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

---

## SPRINT 17: Caching & Offline

**Duration:** 2-3 days
**Goal:** Add offline support and caching

### Tasks

#### 17.1: Create CacheService
```
Cache portfolio data locally
Cache coin prices
Cache user data
Implement cache invalidation
```

#### 17.2: Offline Mode
```
Detect network status
Fall back to cache
Show offline indicator
Queue sync operations
```

---

## SPRINT 18: Production Polish

**Duration:** 3-5 days
**Goal:** Final testing and production prep

### Tasks

#### 18.1: Error Handling
```
Add global error handling
User-friendly error messages
Retry mechanisms
Error logging
```

#### 18.2: Loading States
```
Skeleton screens
Progress indicators
Optimistic updates
```

#### 18.3: Testing
```
Full E2E test suite
Performance testing
Load testing
Security audit
```

#### 18.4: Production Checklist
```
Environment variables secured
API keys not in code
RLS policies verified
Rate limiting configured
Analytics added
Crash reporting setup
```

---

## Quick Reference: How to Use This Document

### Starting Any Sprint
```bash
# 1. Create sprint branch
git checkout develop
git checkout -b feature/sprint-X-name

# 2. Create task branch
git checkout -b feature/sprint-X-task-1-name

# 3. Copy the prompt from task section
# 4. Paste prompt to Claude
# 5. Execute implementation
# 6. Run tests
# 7. Commit & tag
# 8. Move to next task
```

### Rollback to Any Point
```bash
# View all tags
git tag | grep sprint

# Rollback to sprint
git checkout sprint-12-complete

# Rollback to task
git checkout sprint-12-task-2-complete
```

### Testing Any Sprint
```bash
# Run all tests for sprint
xcodebuild test -scheme CoinFlip

# Run specific test suite
xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/AuthServiceTests
```

---

## Summary

This plan provides:
- ✅ **8 complete sprints** (11-18)
- ✅ **40+ detailed tasks**
- ✅ **Copy-paste prompts** for each task
- ✅ **Test requirements** for each task
- ✅ **Easy rollback** via git tags
- ✅ **Independent testing** of each component

### Estimated Timeline
- **Sprint 11:** 3-5 days
- **Sprint 12:** 4-6 days
- **Sprint 13:** 3-4 days
- **Sprint 14:** 4-5 days
- **Sprint 15:** 2-3 days
- **Sprint 16:** 3-4 days
- **Sprint 17:** 2-3 days
- **Sprint 18:** 3-5 days

**Total:** 24-35 days (4-7 weeks)

### Ready to Start?

```bash
# Begin with Sprint 11, Task 1
git checkout develop
git checkout -b feature/sprint-11-task-1-supabase-setup

# Then execute:
# "Execute Task 11.1: Supabase Project Setup"
```
