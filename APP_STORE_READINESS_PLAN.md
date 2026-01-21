# CoinFlip - App Store Readiness Plan

**Status:** v1.2.1 → App Store Ready
**Estimated Total Time:** 25-35 hours
**Target Submission Date:** [Set your goal]

---

## Overview

This document outlines all required changes to make CoinFlip ready for public App Store release. Tasks are organized by priority and dependency.

---

## Phase 1: Critical Blockers (MUST FIX)
**Time Estimate:** 8-12 hours
**Priority:** Highest - Blocks App Store submission

### 1.1 Legal Documents (3-4 hours)

#### Privacy Policy
**Why Required:** Apple mandates privacy policy for apps collecting user data
**What to Include:**
- Data collected (username, avatar, trading data, device info)
- How data is used (app functionality, leaderboard)
- How data is stored (Supabase, encrypted)
- Third-party services (Supabase, CoinGecko, GeckoTerminal)
- Data retention and deletion
- User rights (access, deletion)
- Contact information

**Template Structure:**
```markdown
# Privacy Policy for CoinFlip

Last updated: [Date]

## 1. Information We Collect
- Username and avatar emoji (you provide)
- Trading history and portfolio data
- Device information for app functionality

## 2. How We Use Your Information
- Provide app features (trading simulation, leaderboard)
- Improve user experience

## 3. Third-Party Services
- Supabase (data storage)
- CoinGecko API (cryptocurrency prices)
- GeckoTerminal API (viral coin data)

## 4. Data Security
- Stored securely on Supabase with encryption
- Anonymous authentication (no email/password required)

## 5. Your Rights
- Request data deletion via support email
- Data automatically deleted on account reset

## 6. Contact
Email: avinashgdn@gmail.com
```

**Hosting Options:**
1. **GitHub Pages** (Free, Easy)
   - Create `/docs/privacy-policy.html` in repo
   - Enable GitHub Pages in repo settings
   - URL: `https://YOUR_USERNAME.github.io/CoinFlip/privacy-policy.html`

2. **Supabase Storage** (Alternative)
   - Upload HTML to Supabase Storage
   - Make bucket public
   - Get public URL

**Implementation:**
```swift
// In ProfileView.swift:72-76
SettingsRow(
    icon: "lock.shield.fill",
    title: "Privacy Policy",
    iconColor: .textSecondary
) {
    if let url = URL(string: "https://YOUR_URL/privacy-policy.html") {
        UIApplication.shared.open(url)
    }
    HapticManager.shared.impact(.light)
}
```

#### Terms of Service
**What to Include:**
- Acceptance of terms
- Virtual currency disclaimer (no real money)
- Age requirements (13+ or 12+ based on age rating)
- Prohibited activities
- Liability limitations
- Changes to terms
- Governing law

**Template Structure:**
```markdown
# Terms of Service for CoinFlip

## 1. Acceptance of Terms
By using CoinFlip, you agree to these terms.

## 2. Description of Service
CoinFlip is a cryptocurrency trading SIMULATOR for educational purposes.
All trades use VIRTUAL MONEY. No real money is involved.

## 3. User Accounts
- Must be 12+ years old
- One account per user
- No sharing accounts

## 4. Virtual Currency
- All currency in the app is VIRTUAL
- Cannot be converted to real money
- Has no real-world value

## 5. Disclaimers
- NOT financial advice
- Educational purposes only
- Prices are real but trades are simulated
- Do not make real investments based on this app

## 6. Liability
We are not liable for any decisions you make based on this app.

## 7. Termination
We reserve the right to terminate accounts for violations.

## 8. Contact
Email: avinashgdn@gmail.com
```

**Implementation:** Same as Privacy Policy

#### Help & Support
**Implementation:**
```swift
// In ProfileView.swift:56-62
SettingsRow(
    icon: "questionmark.circle.fill",
    title: "Help & Support",
    iconColor: .primaryPurple
) {
    if let url = URL(string: "mailto:avinashgdn@gmail.com?subject=CoinFlip%20Support") {
        UIApplication.shared.open(url)
    }
    HapticManager.shared.impact(.light)
}
```

### 1.2 App Icon (30 minutes)

**Current Issue:** Only has AppIcon.png, needs all sizes in asset catalog

**Solution 1: Run Existing Script**
```bash
cd /Users/avinash/Code/CoinFlip/CoinFlip/Assets.xcassets/AppIcon.appiconset/
swift generate_icon.swift
```

**Solution 2: Use Xcode**
1. Open Xcode
2. Navigate to Assets.xcassets → AppIcon
3. Drag AppIcon.png (1024x1024) into the "App Store iOS" slot
4. Xcode will auto-generate other sizes

**Verify:**
- Check that all device sizes have images
- Build and run - icon should appear on home screen

### 1.3 Privacy Manifest (1 hour)

**Why Required:** iOS 17+ requires PrivacyInfo.xcprivacy for apps using certain APIs

**Create File:**
```bash
# In Xcode: File → New → File → App Privacy File
# Or create manually:
```

**File Location:** `/Users/avinash/Code/CoinFlip/CoinFlip/PrivacyInfo.xcprivacy`

**Content:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeUserID</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeGameplayContent</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### 1.4 Fix Hardcoded Version (15 minutes)

**Current:** ProfileView.swift:83 shows "1.0.0"
**Fix:**
```swift
// In ProfileView.swift, replace line 83
value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
```

### 1.5 Financial Disclaimer (1 hour)

**Option 1: Add to Onboarding (Recommended)**
Create new onboarding page at the END:

```swift
// In OnboardingViewModel.swift, add to pages array:
OnboardingPageData(
    emoji: "⚠️",
    title: "Important Disclaimer",
    subtitle: "This app uses VIRTUAL money for educational purposes. All trades are simulated. Not financial advice."
)
```

**Option 2: Add to Profile → About Section**
```swift
// In ProfileView.swift, add new row:
SettingsRow(
    icon: "exclamationmark.triangle.fill",
    title: "Disclaimer",
    subtitle: "Educational simulation only",
    iconColor: .orange
) {
    showDisclaimer = true
}

// Add sheet with full disclaimer
.sheet(isPresented: $showDisclaimer) {
    DisclaimerView()
}
```

---

## Phase 2: App Store Assets (6-10 hours)
**Priority:** High - Required for submission

### 2.1 Screenshots (4-6 hours)

**Required Sizes:**
- 6.7" Display (iPhone 15 Pro Max, 14 Pro Max)
- 6.5" Display (iPhone 11 Pro Max, XS Max)
- 5.5" Display (iPhone 8 Plus)

**Best Practices:**
- 3-5 screenshots per size
- Show key features in order:
  1. Home screen with trending coins
  2. Trading screen (Buy view)
  3. Portfolio view with holdings
  4. Leaderboard
  5. Viral coins view

**How to Create:**
1. Run app on simulator for each size
2. Cmd+S to save screenshot
3. Use Xcode's built-in screenshot tool (Cmd+Shift+M → Capture Screenshot)
4. OR use Simulator → File → Save Screen

**Enhancement Tool (Optional):**
- Use [Previewed.app](https://previewed.app) or [AppLaunchpad](https://theapplaunchpad.com) to add device frames
- Add text overlays explaining features

### 2.2 App Description (1-2 hours)

**Template:**
```
🪙 Learn Crypto Trading Risk-Free!

CoinFlip is a fun and educational cryptocurrency trading simulator. Practice buying and selling real coins with virtual money - no risk, all the learning!

KEY FEATURES:
📈 Real-Time Prices - Track 100+ cryptocurrencies with live market data
💰 Virtual Trading - Start with $1,000 and build your portfolio
🔥 Discover Viral Coins - Find newly launched meme coins across 200+ blockchains
🏆 Compete on Leaderboards - See how you rank against other traders
📊 Track Performance - Monitor your gains and losses
🎯 Daily Featured Coins - New opportunities every day

PERFECT FOR:
• Crypto beginners wanting to learn without risk
• Experienced traders testing strategies
• Anyone curious about cryptocurrency markets
• Students learning about investing

SAFE & EDUCATIONAL:
✓ 100% virtual money - no real funds involved
✓ Real cryptocurrency prices
✓ No ads or in-app purchases
✓ Safe environment to learn market dynamics

Start your crypto journey today with CoinFlip!

DISCLAIMER: This app is for educational and entertainment purposes only. All trades are simulated. Not financial advice.
```

### 2.3 Keywords (30 minutes)

**Recommended Keywords:**
```
crypto, cryptocurrency, bitcoin, trading, simulator, portfolio, investment, education, meme coin, learning, virtual trading, stock market, leaderboard, ethereum, coins
```

**Guidelines:**
- Max 100 characters
- Separate with commas
- Avoid duplicating words in app name/subtitle
- Research competitors' keywords

### 2.4 Age Rating (30 minutes)

**Recommended: 12+**

**Reasons:**
- Simulated gambling/trading mechanics
- Financial content
- Leaderboard competition

**Apple's Questionnaire:**
- Simulated Gambling: YES (trading simulation)
- Unrestricted Web Access: NO
- Gambling & Contests: NO (virtual currency only)

### 2.5 Category (15 minutes)

**Primary Category Options:**

**Finance** (Recommended)
- Pros: Accurate representation, users browsing finance apps will find it
- Cons: More competition

**Education**
- Pros: Less competition, emphasizes learning aspect
- Cons: Users might not expect trading features

**Recommendation:** Choose **Finance** as primary, **Education** as secondary

---

## Phase 3: Education & UX (8-12 hours)
**Priority:** High - Critical for user success

### 3.1 Learn Section in Profile (3-4 hours)

**Create New View:** `LearnView.swift`

```swift
struct LearnView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Crypto Basics
                    LearnSection(
                        icon: "🪙",
                        title: "What is Cryptocurrency?",
                        content: "Digital money that exists on blockchain networks. Bitcoin was the first, now there are thousands!"
                    )

                    LearnSection(
                        icon: "📊",
                        title: "How to Read Charts",
                        content: "Green means price went up, red means down. The sparkline shows 7 days of price history."
                    )

                    LearnSection(
                        icon: "💰",
                        title: "Buying & Selling",
                        content: "Buy low, sell high! Your profit/loss is calculated from the difference between buy and sell price."
                    )

                    LearnSection(
                        icon: "🔥",
                        title: "What are Viral Coins?",
                        content: "Newly launched coins with high volatility. Great for learning but very risky in real trading!"
                    )

                    LearnSection(
                        icon: "🏆",
                        title: "Leaderboard Rankings",
                        content: "Everyone starts with $1,000. Grow your net worth to climb the leaderboard!"
                    )
                }
                .padding()
            }
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LearnSection: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text(icon)
                        .font(.system(size: 40))
                    Text(title)
                        .font(.headline3)
                        .foregroundColor(.textPrimary)
                }

                Text(content)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
```

**Add to ProfileView:**
```swift
SettingsRow(
    icon: "book.fill",
    title: "Learn About Crypto",
    iconColor: .primaryGreen
) {
    showLearnSection = true
    HapticManager.shared.impact(.light)
}
```

### 3.2 Viral Coins Education (1 hour)

**Add Header to ViralCoinsView:**

```swift
// Add after NavigationStack, before ScrollView
VStack(spacing: 0) {
    // Educational Banner
    HStack(spacing: Spacing.sm) {
        Image(systemName: "info.circle.fill")
            .foregroundColor(.blue)
            .font(.title3)

        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("New & Trending Coins")
                .font(.labelMedium)
                .foregroundColor(.textPrimary)

            Text("Recently launched with high volatility - perfect for learning!")
                .font(.labelSmall)
                .foregroundColor(.textSecondary)
        }
        Spacer()
    }
    .padding(Spacing.md)
    .background(Color.blue.opacity(0.1))
    .cornerRadius(Spacing.sm)
    .padding(.horizontal, Spacing.md)
    .padding(.top, Spacing.md)

    // Existing ScrollView content...
}
```

### 3.3 Portfolio Reset Confirmation (30 minutes)

**Add to ProfileView:**

```swift
@State private var showResetConfirmation = false

// Replace existing reset button with:
SettingsRow(
    icon: "arrow.counterclockwise.circle.fill",
    title: "Reset Portfolio",
    subtitle: "Start over with $1,000",
    iconColor: .primaryPurple
) {
    showResetConfirmation = true
}
.alert("Reset Portfolio?", isPresented: $showResetConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Reset", role: .destructive) {
        viewModel.resetPortfolio()
    }
} message: {
    Text("This will delete all your holdings and transactions. You'll start fresh with $1,000. This cannot be undone.")
}
```

### 3.4 Trading Tooltips (2-3 hours)

**Create Tooltip Component:**

```swift
struct InfoTooltip: View {
    let text: String
    @State private var showTooltip = false

    var body: some View {
        Button {
            showTooltip = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.textSecondary)
                .font(.caption)
        }
        .alert("Info", isPresented: $showTooltip) {
            Button("Got it") { }
        } message: {
            Text(text)
        }
    }
}
```

**Add to SellView (line 248):**

```swift
HStack {
    Text("Cost basis")
        .font(.bodySmall)
        .foregroundColor(.textSecondary)
    InfoTooltip(text: "The total amount you paid for this quantity of coins.")
    Spacer()
    Text(Formatters.currency(costBasis))
        .font(.bodySmall)
        .foregroundColor(.textMuted)
}
```

**Add to BuyView:**
```swift
HStack {
    Text("Order Summary")
        .font(.headline3)
        .foregroundColor(.textPrimary)
    InfoTooltip(text: "Review your purchase before confirming. You can sell anytime from your Portfolio.")
    Spacer()
}
```

### 3.5 Portfolio Metrics Helper (1 hour)

**Add to PortfolioView (line 13):**

```swift
HStack {
    Text("Net Worth")
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
    InfoTooltip(text: "Your total value: cash + current value of all holdings")
}
```

### 3.6 First Trade Guidance (1-2 hours)

**Add to HomeView:**

```swift
@AppStorage("hasCompletedFirstTrade") private var hasCompletedFirstTrade = false
@State private var showFirstTradeHint = false

// In body, after NavigationStack:
.overlay(
    Group {
        if !hasCompletedFirstTrade && showFirstTradeHint {
            VStack {
                Spacer()
                HStack {
                    Text("💡 Tap any coin to make your first trade!")
                        .font(.bodyMedium)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.primaryGreen)
                        .cornerRadius(Spacing.md)
                        .shadow(radius: 10)
                        .padding()
                    Spacer()
                }
            }
            .transition(.move(edge: .bottom))
        }
    }
)
.onAppear {
    if !hasCompletedFirstTrade {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showFirstTradeHint = true
            }
        }
    }
}

// Mark as completed after successful buy in BuyView
UserDefaults.standard.set(true, forKey: "hasCompletedFirstTrade")
```

### 3.7 Improve Error Messages (1 hour)

**Create ErrorView Component:**

```swift
struct ErrorView: View {
    let message: String
    let emoji: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(emoji)
                .font(.system(size: 64))

            Text("Oops!")
                .font(.headline1)
                .foregroundColor(.textPrimary)

            Text(message)
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PrimaryButton(title: "Try Again") {
                action()
            }
        }
        .padding()
    }
}
```

**Use throughout app for error states**

---

## Phase 4: Polish (4-6 hours)
**Priority:** Medium - Improves UX but not critical

### 4.1 Onboarding Skip Button (15 minutes)

```swift
// In OnboardingView.swift, line 15:
if viewModel.currentPage > 0 && viewModel.currentPage < viewModel.pages.count - 1 {
    Button("Skip") {
        completeOnboarding()
    }
    // ... rest of button styling
}
```

### 4.2 System Theme Option (30 minutes)

**Update ProfileView:**

```swift
private func toggleTheme() {
    // Cycle through: dark → system → light → dark
    let newTheme: Theme = switch themeService.currentTheme {
        case .dark: .system
        case .system: .light
        case .light: .dark
    }
    themeService.setTheme(newTheme)
}

// Update icon to show current theme
Image(systemName:
    themeService.currentTheme == .dark ? "moon.fill" :
    themeService.currentTheme == .light ? "sun.max.fill" :
    "circle.lefthalf.filled"
)
```

### 4.3 Transaction History View (2-3 hours)

**Create TransactionHistoryView.swift:**

```swift
struct TransactionHistoryView: View {
    let transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formatDate(date))) {
                        ForEach(groupedByDate[date] ?? []) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("Transaction History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var groupedByDate: [Date: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.timestamp)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
```

**Add to PortfolioView:**

```swift
Button("View All") {
    showTransactionHistory = true
}
.sheet(isPresented: $showTransactionHistory) {
    TransactionHistoryView(transactions: viewModel.transactions)
}
```

### 4.4 Username Validation Improvement (30 minutes)

```swift
// In UsernameSetupView, move validation text ABOVE input:
VStack(alignment: .leading, spacing: Spacing.sm) {
    Text("Choose Username")
        .font(.headline3)
        .foregroundColor(.textPrimary)

    Text("3-20 characters, letters and numbers only")
        .font(.labelSmall)
        .foregroundColor(.textMuted)

    TextField("Enter username", text: $username)
        // ... existing styling
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cardRadius)
                .stroke(
                    username.isEmpty ? Color.textMuted.opacity(0.2) :
                    isValidUsername ? Color.primaryGreen :
                    Color.lossRed,
                    lineWidth: 1
                )
        )
}
```

---

## Phase 5: Testing & Submission (4-6 hours)
**Priority:** Final stage

### 5.1 Testing Checklist

**Functionality Testing:**
- [ ] Privacy Policy link opens correctly
- [ ] Terms of Service link opens correctly
- [ ] Help & Support mailto link works
- [ ] All tooltips display correctly
- [ ] Learn section accessible and readable
- [ ] Portfolio reset confirmation works
- [ ] First trade guidance appears
- [ ] App icon displays on home screen
- [ ] Version number reads from Bundle

**Device Testing:**
- [ ] Test on iPhone SE (smallest screen)
- [ ] Test on iPhone 15 Pro Max (largest screen)
- [ ] Test on iPad (if supporting)
- [ ] Test in dark mode
- [ ] Test with poor network connection
- [ ] Test offline mode

**User Flow Testing:**
- [ ] New user onboarding complete flow
- [ ] First trade experience
- [ ] Buy → Portfolio → Sell flow
- [ ] Reset portfolio flow
- [ ] View leaderboard
- [ ] Access all help resources

### 5.2 User Testing (2-3 hours)

**Find 3-5 testers who:**
- Have never used the app
- Vary in crypto knowledge (at least 1 novice)
- Different age ranges

**Testing Script:**
1. Give them the app with no instructions
2. Ask them to:
   - Set up their account
   - Make their first trade
   - Check their portfolio
   - Find help/learn resources
3. Observe and take notes on:
   - Where they get confused
   - What they skip
   - What questions they ask
4. Ask after testing:
   - "What was most confusing?"
   - "What would you change?"
   - "Would you use this app?"

### 5.3 App Store Connect Setup (1-2 hours)

**Before You Start:**
- Apple Developer account ($99/year)
- App-specific password for App Store Connect
- All assets ready (screenshots, icon, description)

**Steps:**
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+"
3. Fill in app information:
   - Name: CoinFlip
   - Primary Language: English
   - Bundle ID: [Your bundle ID]
   - SKU: [Unique identifier]
4. Select availability (all countries or specific)
5. Upload screenshots for all device sizes
6. Write app description (use template from Phase 2)
7. Add keywords
8. Set pricing (Free)
9. Set age rating (12+)
10. Add app icon (1024x1024)
11. Fill in contact information
12. Add privacy policy URL
13. Add support URL

### 5.4 Build & Upload (30 minutes)

**In Xcode:**
1. Select "Any iOS Device (arm64)" as build target
2. Product → Archive
3. Wait for archive to complete
4. Organizer opens automatically
5. Click "Distribute App"
6. Choose "App Store Connect"
7. Upload build
8. Wait for processing (10-30 minutes)

**In App Store Connect:**
1. Select your app
2. Click on version
3. Under "Build" select the uploaded build
4. Fill in "What's New in This Version"
5. Submit for Review

### 5.5 Review Preparation

**Apple Will Check:**
- All features work as described
- No crashes
- Privacy policy is accurate
- Age rating is appropriate
- No hidden features
- App performs as expected

**Review Notes to Include:**
```
Test Account: (If you implement login)
- Username: testuser
- Password: testpass123

Notes for Reviewer:
- This is a cryptocurrency trading SIMULATOR
- All currency is VIRTUAL
- Prices are real from CoinGecko API
- No real money transactions
- Educational purpose only

How to Test:
1. Complete onboarding
2. Tap any coin to buy with virtual cash
3. Check portfolio for holdings
4. Tap a holding to sell
5. View leaderboard rankings
```

---

## Implementation Order

**Week 1: Critical Blockers**
Day 1-2: Legal documents (privacy, terms, hosting)
Day 3: Implement policy links, help support
Day 4: App icon generation, privacy manifest
Day 5: Version fix, financial disclaimer

**Week 2: App Store Assets & Education**
Day 6-7: Screenshots for all device sizes
Day 8: App Store description and keywords
Day 9-10: Learn section, tooltips, confirmations

**Week 3: Polish & Testing**
Day 11-12: Onboarding improvements, UI polish
Day 13: Internal testing
Day 14: User testing with 3-5 people
Day 15: Fix issues found in testing

**Week 4: Submission**
Day 16-17: App Store Connect setup
Day 18: Build and upload
Day 19: Submit for review
Day 20: Monitor review status

---

## Success Metrics

**Phase 1 Complete When:**
- [ ] All policy links work
- [ ] App icon displays everywhere
- [ ] Privacy manifest included
- [ ] Version reads from Bundle
- [ ] Disclaimer visible

**Phase 2 Complete When:**
- [ ] Screenshots for 3 device sizes
- [ ] App Store description written
- [ ] Keywords selected
- [ ] Age rating determined
- [ ] Category chosen

**Phase 3 Complete When:**
- [ ] Learn section accessible
- [ ] Viral coins explained
- [ ] Reset has confirmation
- [ ] Tooltips on key features
- [ ] First trade guidance works

**Phase 4 Complete When:**
- [ ] Onboarding skip improved
- [ ] Theme options complete
- [ ] Transaction history available
- [ ] Username validation clear

**Phase 5 Complete When:**
- [ ] All features tested
- [ ] User testing completed
- [ ] Issues fixed
- [ ] App Store Connect setup
- [ ] App submitted for review

---

## Emergency Contacts & Resources

**Apple Support:**
- App Store Connect: https://appstoreconnect.apple.com
- Developer Forums: https://developer.apple.com/forums/
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

**Legal Templates:**
- Privacy Policy Generator: https://www.privacypolicies.com
- Terms Generator: https://www.termsfeed.com

**Design Resources:**
- Screenshot Tool: https://previewed.app
- App Icon: https://appicon.co

**Your Resources:**
- Support Email: avinashgdn@gmail.com
- GitHub Repo: [Your repo URL]
- Privacy Policy URL: [To be created]
- Terms of Service URL: [To be created]

---

## Notes

- All times are estimates - adjust based on your pace
- Don't skip Phase 1 - these are hard requirements
- Phase 3 significantly improves user experience
- Consider beta testing before public release
- Apple review typically takes 1-3 days
- Be prepared to respond to reviewer questions

---

**Good luck with your App Store launch! 🚀**
