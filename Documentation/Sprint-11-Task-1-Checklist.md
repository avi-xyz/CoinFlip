# Sprint 11, Task 11.1: Supabase Project Setup - Completion Checklist

## ✅ What's Been Done

### Files Created:
1. **Services/Config/EnvironmentConfig.swift** - Configuration for Supabase credentials
2. **Services/SupabaseService.swift** - Singleton service for Supabase client
3. **CoinFlipTests/Unit/Services/SupabaseServiceTests.swift** - Unit tests
4. **CoinFlipTests/README.md** - Testing documentation

### Code Updated:
- **CoinFlipApp.swift** - Added Supabase initialization on app launch

## 🔧 Your Action Items (Complete in Order)

### Step 1: Create Supabase Project (5-10 minutes)

1. Go to https://supabase.com/dashboard
2. Sign up/Login (use GitHub for quick signup)
3. Click "New Project"
4. Fill in:
   - Name: `coinflip`
   - Database Password: Generate strong password (SAVE THIS!)
   - Region: Choose closest to you (e.g., `us-west-1`)
5. Click "Create new project" (takes ~2 minutes)

### Step 2: Get Your Credentials (1 minute)

1. In your new Supabase project dashboard
2. Go to **Settings** → **API**
3. Copy these two values:
   - **Project URL** (e.g., `https://abcdefgh.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### Step 3: Add Supabase Swift SDK (2 minutes)

1. Open `CoinFlip.xcodeproj` in Xcode
2. Click on project in navigator (top "CoinFlip")
3. Select "CoinFlip" target
4. Go to "Package Dependencies" tab
5. Click "+" button
6. Enter: `https://github.com/supabase/supabase-swift`
7. Click "Add Package"
8. Select these products:
   - ✅ Supabase
   - ✅ SupabaseAuth
   - ✅ SupabasePostgresql
9. Click "Add Package"

### Step 4: Add Files to Xcode Project (2 minutes)

Add the new service files:
1. In Xcode, right-click on "CoinFlip" folder in navigator
2. Select "Add Files to CoinFlip"
3. Navigate to and select the `Services` folder
4. Make sure "CoinFlip" target is checked
5. Click "Add"

Add the test files:
1. In Xcode, File → New → Target
2. Choose "Unit Testing Bundle"
3. Product Name: `CoinFlipTests`
4. Click "Finish"
5. Right-click on "CoinFlipTests" folder in navigator
6. Select "Add Files to CoinFlip"
7. Navigate to `CoinFlipTests/Unit/Services/SupabaseServiceTests.swift`
8. Make sure "CoinFlipTests" target is checked
9. Click "Add"

### Step 5: Configure Credentials (1 minute)

1. Open `Services/Config/EnvironmentConfig.swift` in Xcode
2. Find line 19: `return "YOUR_SUPABASE_URL_HERE"`
3. Replace with your Project URL: `return "https://YOUR_PROJECT_ID.supabase.co"`
4. Find line 30: `return "YOUR_SUPABASE_ANON_KEY_HERE"`
5. Replace with your anon key: `return "eyJhbGci...YOUR_ACTUAL_KEY"`
6. Save the file (Cmd + S)

### Step 6: Build and Test (2 minutes)

1. Clean build: `Cmd + Shift + K`
2. Build: `Cmd + B`
3. Run tests: `Cmd + U`

**Expected results:**
- Build succeeds ✅
- App launches with console message: `✅ [DEBUG] Supabase configured successfully`
- All 8 tests in `SupabaseServiceTests` pass ✅

### Step 7: Verify Integration (1 minute)

1. Run the app (Cmd + R)
2. Check Xcode console (bottom pane)
3. You should see:
   ```
   ✅ SupabaseService: Successfully initialized
   ✅ [DEBUG] Supabase configured successfully
   ```

If you see warnings instead, double-check your credentials in EnvironmentConfig.swift

## 🧪 Run Tests

```bash
# Run all tests
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only Supabase tests
xcodebuild test -scheme CoinFlip -only-testing:CoinFlipTests/SupabaseServiceTests
```

## ✅ Acceptance Criteria

Before moving to Task 11.2, verify:

- [ ] Supabase project created and accessible at dashboard
- [ ] Supabase Swift SDK installed via SPM
- [ ] `SupabaseService.swift` created and added to project
- [ ] `EnvironmentConfig.swift` configured with real credentials
- [ ] App initializes Supabase on launch (check console logs)
- [ ] All 8 unit tests pass
- [ ] No build errors
- [ ] Console shows "✅ Supabase configured successfully"

## 📝 Commit Your Work

Once all acceptance criteria are met:

```bash
git add .
git commit -m "feat(sprint-11): Task 11.1 - Supabase project setup

- Created SupabaseService singleton for client management
- Added EnvironmentConfig for credentials
- Configured Supabase Swift SDK via SPM
- Initialized Supabase on app launch
- Created unit tests for service initialization
- All tests passing

Task: Sprint 11, Task 11.1
Files: Services/SupabaseService.swift, Services/Config/EnvironmentConfig.swift
Tests: 8 unit tests

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git tag sprint-11-task-1-complete
```

## 🐛 Troubleshooting

### Build Errors

**"No such module 'Supabase'"**
- Supabase package not installed
- Go back to Step 3 and add the package

**"Cannot find 'SupabaseService' in scope"**
- Service files not added to Xcode target
- Right-click file → Target Membership → Check "CoinFlip"

**Tests not showing in Test Navigator**
- Test files not added to test target
- Right-click test file → Target Membership → Check "CoinFlipTests"

### Runtime Warnings

**"⚠️ Supabase not configured"**
- Credentials not set in EnvironmentConfig.swift
- Go back to Step 5 and add your credentials

**"⚠️ Invalid Supabase URL format"**
- URL doesn't start with `https://`
- URL doesn't contain `supabase.co`
- Double-check you copied the correct Project URL

### Test Failures

**Tests failing with "not configured" errors**
- This is expected if you haven't added credentials yet
- Add credentials in EnvironmentConfig.swift
- Re-run tests

## 📚 Next Steps

Once this task is complete and committed:
- Move to **Sprint 11, Task 11.2: Database Schema Design**
- This will create the PostgreSQL tables for users, portfolios, holdings, and transactions

---

**Need Help?** Check the troubleshooting section or review `/Documentation/QUICK-START.md`
