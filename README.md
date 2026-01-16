# CoinFlip - Meme Coin Trading Simulator 🪙

A fun iOS app for simulating meme coin trading with real-time crypto prices. Track your portfolio, compete on leaderboards, and discover trending meme coins!

![Platform](https://img.shields.io/badge/platform-iOS%2018.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### 🏠 Home Screen
- **Today's Coin**: Daily featured meme coin with skip functionality
- **Trending Meme Coins**: Live data from CoinGecko API
- **Net Worth Display**: Real-time portfolio valuation
- **Pull-to-Refresh**: Update prices on demand

### 💰 Trading
- **Buy Coins**: Purchase with virtual cash ($1,000 starting balance)
- **Sell Holdings**: Sell in percentages (25%, 50%, 75%, 100%)
- **Real-time Prices**: Live cryptocurrency data
- **Transaction History**: Track all your trades

### 📊 Portfolio
- **Holdings Overview**: See all your coin positions
- **Performance Tracking**: Monitor gains/losses
- **Cash Balance**: Track available funds
- **Portfolio Reset**: Start fresh anytime

### 🏆 Leaderboard
- **Global Rankings**: Compete with other users
- **Net Worth Based**: Ranked by portfolio value
- **Real-time Updates**: See how you stack up

### 👤 Profile
- **User Stats**: View your trading history
- **Avatar System**: Customize with emojis
- **Portfolio Management**: Reset or adjust settings

## Screenshots

<table>
  <tr>
    <td><img src="docs/screenshots/home.png" width="200" alt="Home Screen"/></td>
    <td><img src="docs/screenshots/portfolio.png" width="200" alt="Portfolio"/></td>
    <td><img src="docs/screenshots/trading.png" width="200" alt="Trading"/></td>
  </tr>
</table>

## Tech Stack

### Architecture
- **SwiftUI**: Modern declarative UI
- **MVVM**: Model-View-ViewModel pattern
- **Combine**: Reactive programming
- **Async/Await**: Modern concurrency

### Backend
- **Supabase**: Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Row Level Security (RLS)
  - Anonymous authentication

### APIs
- **CoinGecko API**: Real-time cryptocurrency data
- **Supabase REST API**: Data persistence

### Dependencies (Swift Package Manager)
- [Supabase Swift](https://github.com/supabase/supabase-swift) - 2.39.0
- Swift Crypto - 4.2.0
- Swift HTTP Types - 1.5.1
- Swift Clocks - 1.0.6

## Project Structure

```
CoinFlip/
├── App/
│   ├── CoinFlipApp.swift        # App entry point
│   └── ContentView.swift        # Root view
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Home/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Portfolio/
│   ├── Trading/
│   ├── Leaderboard/
│   └── Profile/
├── Models/
│   ├── Coin.swift
│   ├── Portfolio.swift
│   ├── Holding.swift
│   └── Transaction.swift
├── Services/
│   ├── AuthService.swift
│   ├── CryptoAPIService.swift
│   ├── SupabaseDataService.swift
│   └── DataServiceProtocol.swift
├── Components/
│   ├── Cards/
│   ├── Buttons/
│   └── Display/
├── Core/
│   ├── Theme/
│   ├── Extensions/
│   └── Utilities/
└── Assets.xcassets/
```

## Setup Instructions

### Prerequisites
- Xcode 16.0 or later
- iOS 18.0+ deployment target
- Supabase account
- CoinGecko API access (free tier)

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/CoinFlip.git
cd CoinFlip
```

### 2. Configure Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL schema (see `docs/database-schema.sql`)
3. Update `CoinFlip/Services/SupabaseService.swift`:

```swift
let url = URL(string: "YOUR_SUPABASE_URL")!
let key = "YOUR_SUPABASE_ANON_KEY"
```

### 3. Database Schema

The app requires these Supabase tables:
- `users` - User profiles
- `portfolios` - Portfolio data
- `holdings` - Coin holdings
- `transactions` - Trade history

See `docs/database-schema.sql` for full schema.

### 4. Install Dependencies

Open `CoinFlip.xcodeproj` in Xcode. Dependencies will be resolved automatically via Swift Package Manager.

### 5. Build and Run

1. Select your target device/simulator
2. Press `Cmd+R` or click the Play button
3. Sign in with your Apple ID for code signing

## Configuration

### Environment Modes

Toggle between real and mock data in `EnvironmentConfig.swift`:

```swift
struct EnvironmentConfig {
    static let useMockData = false  // Set to true for offline development
}
```

### Rate Limiting

The app includes automatic retry logic for Supabase rate limits:
- Exponential backoff (1s → 4s → 9s)
- Up to 3 retry attempts
- User-friendly error messages

See `docs/RATE_LIMIT_FIX.md` for details.

## Testing

### Unit Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### UI Tests
```bash
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CoinFlipUITests
```

### Test Documentation
- `CoinFlipUITests/PARENT_IDENTIFIER_MASKING_FIX.md` - Accessibility testing guide
- `CoinFlipUITests/RATE_LIMIT_FIX.md` - Rate limit handling

## Key Features Implementation

### "Coin of the Day" System

Featured coin rotates daily:
- Random selection each day
- Persisted in UserDefaults
- Skip hides until tomorrow
- Resets on portfolio reset

Implementation: `HomeViewModel.swift:179-261`

### Real-time Data

Cryptocurrency prices from CoinGecko:
- 20 trending meme coins
- Live price updates
- 7-day sparkline charts
- 24h price changes

Implementation: `CryptoAPIService.swift`

### Portfolio Management

Full trading simulation:
- Buy/sell with slippage
- Average cost basis tracking
- Real-time P&L calculation
- Transaction history

Implementation: `Portfolio.swift`, `PortfolioViewModel.swift`

## API Rate Limits

### CoinGecko Free Tier
- 10-30 calls/minute
- No API key required
- Rate limit: 429 responses

### Supabase Free Tier
- Automatic retry handling
- Exponential backoff
- Safe for manual testing

## Known Limitations

1. **Demo Mode**: Uses anonymous authentication (no persistent accounts across devices)
2. **Free APIs**: Rate limits on free tiers
3. **Simulated Trading**: Virtual money only, no real trading
4. **iOS Only**: No Android/web versions

## Roadmap

- [ ] Add more meme coins
- [ ] Price alerts and notifications
- [ ] Dark mode support (UI already themed)
- [ ] Social features (share trades)
- [ ] Historical portfolio charts
- [ ] Custom watch lists
- [ ] Achievement system
- [ ] Referral program

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Add comments for complex logic
- Write tests for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

### APIs & Services
- [CoinGecko API](https://www.coingecko.com/en/api) - Cryptocurrency data
- [Supabase](https://supabase.com) - Backend infrastructure

### Design
- App icon generated with Core Graphics
- SF Symbols for iconography
- Custom color palette for meme coin aesthetic

### Developer
Created by [@avinashgdn](https://github.com/avinashgdn)

## Disclaimer

⚠️ **This is a simulation app for entertainment purposes only.**

- No real money involved
- Not financial advice
- Cryptocurrency prices are real but trades are simulated
- Don't make actual investment decisions based on this app

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: avinashgdn@gmail.com

---

**Made with ❤️ and SwiftUI**

*Disclaimer: This app is for educational and entertainment purposes. Not affiliated with any cryptocurrency projects.*
