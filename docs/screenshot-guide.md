# CoinFlip - Screenshot Guide for App Store

**Required:** 3-10 screenshots per device size
**Recommended:** 5 screenshots per size
**Priority:** iPhone only (iPad optional)

---

## Required Device Sizes

Apple requires screenshots for these iPhone sizes:

### 1. **6.7" Display** (REQUIRED)
- iPhone 15 Pro Max
- iPhone 15 Plus
- iPhone 14 Pro Max
- **Resolution:** 1290 x 2796 pixels

### 2. **6.5" Display** (REQUIRED)
- iPhone 11 Pro Max
- iPhone XS Max
- **Resolution:** 1242 x 2688 pixels

### 3. **5.5" Display** (REQUIRED)
- iPhone 8 Plus
- **Resolution:** 1242 x 2208 pixels

---

## Screenshot Strategy

### Show These 5 Screens (in order):

1. **Home Screen** - Trending coins with net worth
2. **Buy Screen** - Trading interface (exciting!)
3. **Portfolio Screen** - Holdings with profit/loss
4. **Leaderboard Screen** - Competitive element
5. **Viral Coins Screen** - Unique feature

---

## How to Capture Screenshots

### Method 1: Using Simulator (Recommended)

#### Step 1: Launch Simulators

```bash
# 6.7" - iPhone 15 Pro Max
xcrun simctl boot "iPhone 15 Pro Max"
open -a Simulator

# 6.5" - iPhone 11 Pro Max
xcrun simctl boot "iPhone 11 Pro Max"
open -a Simulator

# 5.5" - iPhone 8 Plus
xcrun simctl boot "iPhone 8 Plus"
open -a Simulator
```

#### Step 2: Run Your App

```bash
cd /Users/avinash/Code/CoinFlip
xcodebuild -scheme CoinFlip \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
  build
```

Then click "Run" in Xcode or press Cmd+R

#### Step 3: Capture Screenshots

**In Simulator:**
- Press **Cmd+S** to save screenshot
- Screenshots save to Desktop
- File names include device size automatically

**Quick Capture Workflow:**
1. Navigate to Home screen → Cmd+S
2. Tap a coin to open Buy sheet → Cmd+S
3. Close Buy, go to Portfolio tab → Cmd+S
4. Go to Leaderboard tab → Cmd+S
5. Go to Viral tab → Cmd+S

#### Step 4: Repeat for Each Device Size
- Quit simulator
- Launch next size
- Repeat steps 2-3

---

### Method 2: Using Physical Device

**If you have iPhone:**
1. Run app on your device
2. Navigate to each screen
3. Press **Volume Up + Side Button** simultaneously
4. Screenshots save to Photos app
5. AirDrop to Mac or sync via iCloud Photos

**Then resize:**
- Use Preview or Photoshop to crop/resize to exact dimensions
- Match required resolutions above

---

## Screenshot Content Checklist

### Screenshot 1: Home Screen ✨
**Purpose:** Show main interface and value prop

**What to Show:**
- ✅ Net worth display with positive gain
- ✅ Featured coin card
- ✅ 3-4 trending coins visible
- ✅ Clean, uncluttered
- ✅ Show some data (not loading state)

**Pro Tips:**
- Make net worth impressive ($2,500+)
- Show green (profit) for positivity
- Ensure coins have images loaded
- Avoid loading skeletons

**Caption Ideas:**
- "Track 100+ cryptocurrencies in real-time"
- "Learn crypto trading with $1,000 virtual cash"
- "Real prices, zero risk"

---

### Screenshot 2: Buy Screen 💰
**Purpose:** Show trading is easy and fun

**What to Show:**
- ✅ Coin header with price and image
- ✅ Amount slider mid-range ($200-500)
- ✅ Order summary visible
- ✅ Confirm Purchase button prominent
- ✅ Available cash shown

**Pro Tips:**
- Choose a popular coin (Bitcoin, Ethereum, Dogecoin)
- Show coin with positive 24h change (green)
- Amount should be substantial but not max
- Make sure image loaded

**Caption Ideas:**
- "Buy any crypto with one tap"
- "Simple, beautiful trading interface"
- "See exactly what you're buying"

---

### Screenshot 3: Portfolio Screen 📊
**Purpose:** Show portfolio management features

**What to Show:**
- ✅ Net worth card at top
- ✅ 3-4 holdings visible
- ✅ Mix of gains and losses (realistic)
- ✅ Cash balance shown
- ✅ Holdings section title visible

**Pro Tips:**
- Don't show empty portfolio (boring!)
- Variety of coins (BTC, ETH, DOGE, meme coins)
- Some green, some red (authentic)
- Total value should be growing

**Caption Ideas:**
- "Monitor your entire portfolio"
- "Track gains and losses in real-time"
- "See your net worth grow"

---

### Screenshot 4: Leaderboard Screen 🏆
**Purpose:** Show competitive social element

**What to Show:**
- ✅ "Your Rank" card at top
- ✅ Rank number visible (#10-50 range)
- ✅ 5-6 leaderboard entries visible
- ✅ Clear rank numbers, names, values
- ✅ Variety of avatars (emojis)

**Pro Tips:**
- Make your rank competitive (#10-30)
- Show top players with high net worth
- Diverse emoji avatars
- Clean, readable

**Caption Ideas:**
- "Compete with traders worldwide"
- "See how you rank globally"
- "Climb the leaderboard"

---

### Screenshot 5: Viral Coins Screen 🔥
**Purpose:** Show unique feature

**What to Show:**
- ✅ "Viral Coins" title visible
- ✅ Info banner explaining feature
- ✅ 3-4 viral coins visible
- ✅ Chain badges (Solana, Ethereum, Base)
- ✅ High percentage changes (50%+)

**Pro Tips:**
- Show coins with big movements (exciting!)
- Mix of chains (show diversity)
- Some gains, some losses
- Bright, engaging

**Caption Ideas:**
- "Discover newly launched meme coins"
- "200+ blockchains. Infinite opportunities."
- "Catch trends before they explode"

---

## Screenshot Dimensions Reference

### 6.7" Display (iPhone 15 Pro Max)
- **Width:** 1290 px
- **Height:** 2796 px
- **Aspect Ratio:** 9:19.5

### 6.5" Display (iPhone 11 Pro Max)
- **Width:** 1242 px
- **Height:** 2688 px
- **Aspect Ratio:** 9:19.5

### 5.5" Display (iPhone 8 Plus)
- **Width:** 1242 px
- **Height:** 2208 px
- **Aspect Ratio:** 9:16

---

## Optional: Add Text Overlays

### Tools:
- **Previewed.app** (Mac) - $49 one-time
- **AppLaunchpad** (Online) - Free
- **Figma** (Online) - Free
- **Photoshop** - If you have it

### Text Overlay Ideas:

**Screenshot 1:**
```
Real-Time Crypto Prices
Start with $1,000 virtual cash
```

**Screenshot 2:**
```
Buy & Sell Any Crypto
Simple. Fast. Risk-Free.
```

**Screenshot 3:**
```
Track Your Performance
Monitor Gains & Losses
```

**Screenshot 4:**
```
Compete Globally
Climb the Leaderboard
```

**Screenshot 5:**
```
Discover Viral Meme Coins
200+ Blockchains
```

---

## Screenshot Checklist

Before submitting, verify each screenshot:

- [ ] Correct dimensions for device size
- [ ] No loading states or empty screens
- [ ] All images/icons loaded
- [ ] Text is readable
- [ ] Status bar looks clean (optional: hide in simulator)
- [ ] No personal info visible
- [ ] Represents actual app functionality
- [ ] Shows app in best light
- [ ] Order makes sense (tells a story)

---

## Status Bar Considerations

### Option 1: Keep Status Bar (Recommended)
- Shows time, battery, signal
- Looks authentic
- Users expect it

### Option 2: Hide Status Bar
**In Xcode Simulator:**
- Features → Trigger Screenshot
- Check "Optimize for App Store"
- Removes status bar automatically

**Pros:** Cleaner look
**Cons:** Less authentic

**Recommendation:** Keep it. Looks more real.

---

## Quick Capture Script

Save this to capture all screenshots quickly:

```bash
#!/bin/bash

# CoinFlip Screenshot Capture Script

echo "📸 Starting screenshot capture..."

# Device sizes
DEVICES=(
  "iPhone 15 Pro Max"
  "iPhone 11 Pro Max"
  "iPhone 8 Plus"
)

for DEVICE in "${DEVICES[@]}"; do
  echo "📱 Launching $DEVICE..."

  # Boot simulator
  xcrun simctl boot "$DEVICE"
  sleep 2

  # Open Simulator app
  open -a Simulator
  sleep 2

  echo "   Build and run your app, then:"
  echo "   1. Navigate to Home → Press Cmd+S"
  echo "   2. Open Buy screen → Press Cmd+S"
  echo "   3. Go to Portfolio → Press Cmd+S"
  echo "   4. Go to Leaderboard → Press Cmd+S"
  echo "   5. Go to Viral → Press Cmd+S"
  echo ""
  echo "   Press Enter when done with $DEVICE..."
  read

  # Shutdown simulator
  xcrun simctl shutdown "$DEVICE"
done

echo "✅ Screenshot capture complete!"
echo "📁 Check your Desktop for screenshots"
```

**Usage:**
```bash
chmod +x capture-screenshots.sh
./capture-screenshots.sh
```

---

## Organizing Screenshots

### File Naming Convention:

```
coinflip-6.7-01-home.png
coinflip-6.7-02-buy.png
coinflip-6.7-03-portfolio.png
coinflip-6.7-04-leaderboard.png
coinflip-6.7-05-viral.png

coinflip-6.5-01-home.png
coinflip-6.5-02-buy.png
...

coinflip-5.5-01-home.png
coinflip-5.5-02-buy.png
...
```

**Why:**
- Easy to find
- Clear device size
- Correct upload order
- Professional organization

---

## Uploading to App Store Connect

### Step-by-Step:

1. **Log into App Store Connect**
2. **Go to:** My Apps → CoinFlip → App Store tab
3. **Select:** iPhone 6.7" Display
4. **Upload:** Drag 5 screenshots in order
5. **Select:** iPhone 6.5" Display
6. **Upload:** Drag 5 screenshots in order
7. **Select:** iPhone 5.5" Display
8. **Upload:** Drag 5 screenshots in order
9. **Save**

### Important:
- Upload order = display order in App Store
- Can reorder by dragging
- Can add captions (optional but recommended)
- Can localize for different languages

---

## Time Estimate

**Total Time:** 30-60 minutes

- Setup simulators: 10 min
- Capture 6.7" screenshots: 10 min
- Capture 6.5" screenshots: 10 min
- Capture 5.5" screenshots: 10 min
- Organize/rename files: 10 min
- Upload to App Store Connect: 10 min

**Tip:** Do all at once for consistency (same data, same time of day)

---

## Common Mistakes to Avoid

❌ **Empty screens** - Boring and unhelpful
❌ **Loading states** - Looks broken
❌ **Different data** - Confusing across sizes
❌ **Personal info** - Privacy concern
❌ **Wrong dimensions** - Apple rejects
❌ **Too many** - Max 10, optimal is 5
❌ **Random order** - Tell a story!
❌ **Dark mode only** - Show light mode (more popular)

✅ **Populated screens** - Show real functionality
✅ **Loaded data** - Everything looks polished
✅ **Consistent** - Same screens across all sizes
✅ **Clean** - No debug info
✅ **Exact dimensions** - Match requirements
✅ **5 screenshots** - Sweet spot
✅ **Logical order** - User journey
✅ **Light mode** - Broader appeal (or show both!)

---

## Need Help?

**Screenshot Tools:**
- Simulator: Cmd+S
- Xcode: Product → Perform Action → Capture Screenshot
- Previewed.app: https://previewed.app
- AppLaunchpad: https://theapplaunchpad.com

**Questions:**
- Email: avinashgdn@gmail.com
- Check APP_STORE_READINESS_PLAN.md

---

Good luck with your screenshots! 🎉
