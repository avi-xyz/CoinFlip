# Installing CoinFlip on Your Physical iPhone

## Changes Made for Manual Testing

I've optimized the rate limiting for manual use (faster than test mode, but still safe):

1. **Retry delays**: 1s → 4s → 9s (instead of 2s → 8s → 18s for tests)
2. **Initial delay**: 0.5s (instead of 1s)
3. **User-friendly error**: Shows "Connection busy, retrying automatically..." if rate limited

This means:
- Faster app startup and authentication
- Automatic retry if you hit rate limits (unlikely with manual use)
- Safe protection still in place

## Step-by-Step Installation Guide

### Option 1: Install via Xcode (Recommended)

#### 1. Connect Your iPhone

1. Connect your iPhone to your Mac using a USB cable
2. Unlock your iPhone
3. If prompted "Trust This Computer?", tap **Trust**

#### 2. Open Project in Xcode

```bash
# Open the project
open /Users/avinash/Code/CoinFlip/CoinFlip.xcodeproj
```

Or double-click `CoinFlip.xcodeproj` in Finder

#### 3. Select Your Device

1. In Xcode, at the top near the Run button, click the device dropdown
2. Under "iOS Device", select your iPhone (it will show your iPhone's name)

#### 4. Configure Signing

1. Select the **CoinFlip** target in the left sidebar
2. Go to **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** (your Apple ID)
   - If you don't see a team, click "Add Account" and sign in with your Apple ID
5. Xcode will automatically create a provisioning profile

#### 5. Build and Run

1. Click the **Play** button (▶) in Xcode, or press `Cmd+R`
2. Xcode will:
   - Build the app
   - Install it on your iPhone
   - Launch the app

#### 6. Trust Developer Certificate (First Time Only)

On your iPhone:
1. Go to **Settings** > **General** > **VPN & Device Management**
2. Find your Apple ID under "Developer App"
3. Tap it and tap **Trust "[Your Name]"**
4. Confirm by tapping **Trust**

Now the app will launch on your iPhone!

---

### Option 2: Install via Command Line

#### 1. Check Connected Devices

```bash
xcrun xctrace list devices
```

Look for your iPhone in the output (not a Simulator).

#### 2. Build for Device

```bash
cd /Users/avinash/Code/CoinFlip

# Build and install on your device
xcodebuild -scheme CoinFlip \
  -sdk iphoneos \
  -configuration Debug \
  -destination 'platform=iOS,name=YOUR_IPHONE_NAME' \
  build
```

Replace `YOUR_IPHONE_NAME` with your iPhone's name from step 1.

#### 3. Install and Launch

After building, the app will be automatically installed on your device.

---

## Using the App on Your Device

### First Launch

1. **Username Setup**: Create your username and pick an avatar
2. **Onboarding**: Skip or go through the tutorial
3. **Home Screen**: You'll see trending meme coins

### Rate Limiting Protection

If you ever see rate limiting (unlikely with manual use):

1. The app will show: **"Connection busy, retrying automatically..."**
2. It will retry automatically after 1s → 4s → 9s
3. You don't need to do anything, just wait

For manual testing, you'll almost never hit rate limits since you're not creating users rapidly like tests do.

### Testing the App

Test these features:

1. **Browse Coins**: Scroll through trending and featured coins
2. **Buy Coins**: Tap a coin, select amount, buy
3. **View Portfolio**: Check your holdings and net worth
4. **Sell Coins**: Tap a holding, select percentage, sell
5. **Leaderboard**: See top traders
6. **Profile**: View your stats
7. **Pull-to-Refresh**: Pull down on Home screen to refresh prices

### Monitoring in Xcode Console

Keep Xcode open to see console logs:

```
🔐 AuthService: Attempting anonymous sign in...
✅ AuthService: Anonymous sign in successful - User ID: <uuid>
👤 AuthService: User profile found - YourUsername
```

If rate limited (unlikely):
```
⚠️ AuthService: Rate limit hit, retrying in 1.0s (attempt 1/3)...
✅ AuthService: Anonymous sign in successful
```

---

## Troubleshooting

### "Failed to Install App" Error

**Problem**: Xcode can't install the app

**Solution**:
1. Check iPhone is unlocked
2. Trust the computer if prompted
3. Check USB cable connection
4. Try restarting iPhone and Xcode

### "Code Signing Error"

**Problem**: No valid signing certificate

**Solution**:
1. Go to Xcode > Preferences > Accounts
2. Add your Apple ID
3. Select your Apple ID and click "Manage Certificates"
4. Click "+" and create an "iOS Development" certificate
5. Go back to project > Signing & Capabilities
6. Select "Automatically manage signing"
7. Choose your team

### "Developer Mode Required" (iOS 16+)

**Problem**: iOS 16+ requires Developer Mode

**Solution**:
1. On iPhone: Settings > Privacy & Security > Developer Mode
2. Toggle **Developer Mode** ON
3. Restart your iPhone
4. Confirm when prompted

### App Crashes on Launch

**Problem**: App crashes immediately

**Solution**:
1. Check Xcode console for error messages
2. Common causes:
   - Supabase credentials missing
   - Network connection issues
3. Try:
   - Clean build: Product > Clean Build Folder (Shift+Cmd+K)
   - Rebuild and reinstall

### Still Getting Rate Limited

**Problem**: Seeing retry messages frequently

**Solution**:
1. You're probably on Supabase free tier
2. Normal manual use shouldn't trigger this
3. If it happens:
   - Wait a few seconds between operations
   - The app will automatically retry
   - Don't repeatedly close/reopen the app

---

## Removing the App

### From Your iPhone

1. Long-press the CoinFlip app icon
2. Tap "Remove App"
3. Tap "Delete App"

### Reinstalling

Just run the build process again in Xcode.

---

## Testing Checklist

Things to test on your physical device:

- [ ] Account creation flow
- [ ] Username and avatar selection
- [ ] Onboarding tutorial (skip and complete)
- [ ] Home screen loads coins
- [ ] Featured coin card displays
- [ ] Buy flow (select coin, amount, confirm)
- [ ] Portfolio shows holdings
- [ ] Net worth updates correctly
- [ ] Sell flow (select holding, percentage, confirm)
- [ ] Leaderboard displays
- [ ] Profile shows correct info
- [ ] Pull-to-refresh updates prices
- [ ] Navigation between tabs works
- [ ] App survives background/foreground transitions

---

## Rate Limit Details

### What's Protected

The app now has automatic retry logic for:
- Anonymous authentication
- User creation
- Session checks

### Retry Strategy

If rate limited:
- **Attempt 1**: Wait 1 second, retry
- **Attempt 2**: Wait 4 seconds, retry
- **Attempt 3**: Wait 9 seconds, retry
- **After 3 attempts**: Show error to user

### Normal Usage

For manual testing (one person, normal use):
- You should **never** see rate limiting
- Authentication is cached in the session
- Only creates user once
- Subsequent opens use existing session

### When You Might See It

You'll only see rate limiting if you:
- Delete and reinstall the app multiple times quickly
- Force-quit and relaunch repeatedly
- Test on multiple devices simultaneously

Even then, the app handles it automatically!

---

## Performance Tips

### Faster Development Cycle

1. **Keep app running**: Don't force-quit between tests
2. **Use breakpoints**: Debug in Xcode instead of adding logs
3. **Hot reload**: Make small changes and rebuild (Cmd+R)

### Xcode Shortcuts

- **Build & Run**: Cmd+R
- **Stop**: Cmd+.
- **Clean Build**: Shift+Cmd+K
- **Show Console**: Cmd+Shift+Y

---

## Need Help?

If you run into issues:

1. Check the Xcode console for error messages
2. Look for these log prefixes:
   - `🔐` - Authentication related
   - `❌` - Errors
   - `⚠️` - Warnings (like rate limiting)
   - `✅` - Success messages

Common errors are documented in the Troubleshooting section above.

---

**Ready to install?**

1. Connect your iPhone
2. Open the project in Xcode: `open /Users/avinash/Code/CoinFlip/CoinFlip.xcodeproj`
3. Select your device from the dropdown
4. Click the Play button ▶

Enjoy testing CoinFlip on your iPhone! 🚀
