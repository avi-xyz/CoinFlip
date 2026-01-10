# CoinFlip Backend Implementation Plan with Supabase

**Version:** 1.0
**Created:** 2026-01-10
**Status:** Ready to Execute

---

## Table of Contents

1. [Overview](#overview)
2. [Git Branching Strategy](#git-branching-strategy)
3. [Rollback Instructions](#rollback-instructions)
4. [Sprint 11: Backend Foundation](#sprint-11-backend-foundation)
5. [Sprint 12: Authentication & Passkey](#sprint-12-authentication--passkey)
6. [Sprint 13: Real-Time Crypto Prices](#sprint-13-real-time-crypto-prices)
7. [Sprint 14: Portfolio Persistence](#sprint-14-portfolio-persistence)
8. [Sprint 15: Settings Implementation](#sprint-15-settings-implementation)
9. [Sprint 16: Leaderboard Backend](#sprint-16-leaderboard-backend)
10. [Sprint 17: Caching & Offline Support](#sprint-17-caching--offline-support)
11. [Sprint 18: Final Polish & Production](#sprint-18-final-polish--production)

---

## Overview

### Goals
Transform CoinFlip from a frontend prototype into a production-ready app with:
- ✅ User authentication (Passkey support)
- ✅ Real-time cryptocurrency prices
- ✅ Persistent data storage
- ✅ Real user leaderboard
- ✅ Offline support
- ✅ Production-ready error handling

### Technology Stack
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **Crypto API:** CoinGecko API
- **Swift SDK:** Supabase Swift Client
- **Architecture:** MVVM + Service Layer + Protocol-Oriented

### Timeline
- **Quick Path:** 4 weeks (core features)
- **Full Path:** 6-8 weeks (all features + polish)

---

## Git Branching Strategy

### Branch Structure
```
main (production-ready)
  ├── develop (integration)
  │   ├── feature/sprint-11-backend-foundation
  │   │   ├── feature/sprint-11-task-1-supabase-setup
  │   │   ├── feature/sprint-11-task-2-database-schema
  │   │   ├── feature/sprint-11-task-3-service-layer
  │   │   └── feature/sprint-11-task-4-tests
  │   ├── feature/sprint-12-authentication
  │   │   ├── feature/sprint-12-task-1-supabase-auth
  │   │   ├── feature/sprint-12-task-2-auth-views
  │   │   ├── feature/sprint-12-task-3-passkey
  │   │   └── feature/sprint-12-task-4-tests
  │   └── ... (other sprints)
```

### Tagging Convention
```bash
# After completing each task
git tag sprint-11-task-1-complete

# After completing each sprint
git tag sprint-11-complete

# Mark stable releases
git tag v1.0.0-backend-mvp
```

---

## Rollback Instructions

### Rollback to Previous Sprint
```bash
# View all sprint tags
git tag | grep sprint

# Rollback to Sprint 10 (before backend work)
git checkout sprint-10-complete

# Or rollback to specific sprint
git checkout sprint-11-complete
```

### Rollback to Specific Task
```bash
# Rollback to task within sprint
git checkout sprint-11-task-2-complete
```

### Create Rollback Branch
```bash
# If you want to keep current work but start over
git checkout -b backup/sprint-11-attempt-1
git checkout develop
git reset --hard sprint-10-complete
```

---

## SPRINT 11: Backend Foundation

**Duration:** 3-5 days
**Goal:** Set up Supabase, create database schema, implement service layer

### Prerequisites
```bash
# Create sprint branch
git checkout develop
git checkout -b feature/sprint-11-backend-foundation
```

---

### Task 11.1: Supabase Project Setup

**Branch:** `feature/sprint-11-task-1-supabase-setup`

#### Prompt to Execute
```
Execute Task 11.1: Supabase Project Setup

Steps:
1. Create a new Supabase project at https://supabase.com/dashboard
2. Install Supabase Swift SDK via SPM in Xcode
3. Create Services/SupabaseService.swift with singleton client
4. Add environment variables for Supabase URL and anon key
5. Initialize Supabase in CoinFlipApp.swift
6. Create unit tests to verify Supabase client initialization

Acceptance Criteria:
- Supabase project created and accessible
- Swift SDK installed (package: https://github.com/supabase-community/supabase-swift)
- SupabaseService.swift created with shared instance
- Environment variables configured
- App initializes Supabase on launch
- Tests verify client can be instantiated

Files to Create:
- Services/SupabaseService.swift
- Services/Config/EnvironmentConfig.swift
- Tests/Unit/SupabaseServiceTests.swift

Tests Required:
1. testSupabaseClientInitialization() - Verify client can be created
2. testSupabaseURLConfiguration() - Verify URL is valid
3. testSupabaseKeyConfiguration() - Verify anon key is set
```

#### Detailed Implementation Guide

**File 1:** `Services/SupabaseService.swift`
```swift
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: EnvironmentConfig.supabaseURL),
              let key = EnvironmentConfig.supabaseAnonKey else {
            fatalError("Supabase configuration missing. Check EnvironmentConfig.")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )

        print("✅ Supabase initialized: \(url.absoluteString)")
    }
}
```

**File 2:** `Services/Config/EnvironmentConfig.swift`
```swift
import Foundation

struct EnvironmentConfig {
    // TODO: Replace with your actual Supabase project values
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"

    // CoinGecko API (for later sprints)
    static let coinGeckoAPIKey = ""
}
```

**File 3:** `Tests/Unit/SupabaseServiceTests.swift`
```swift
import XCTest
@testable import CoinFlip

class SupabaseServiceTests: XCTestCase {
    func testSupabaseClientInitialization() {
        // Test that singleton can be accessed
        let service = SupabaseService.shared
        XCTAssertNotNil(service.client)
    }

    func testSupabaseURLConfiguration() {
        let url = URL(string: EnvironmentConfig.supabaseURL)
        XCTAssertNotNil(url, "Supabase URL must be valid")
        XCTAssertTrue(url!.absoluteString.contains("supabase.co"),
                     "URL must be a Supabase URL")
    }

    func testSupabaseKeyConfiguration() {
        XCTAssertFalse(EnvironmentConfig.supabaseAnonKey.isEmpty,
                      "Supabase anon key must be set")
        XCTAssertGreaterThan(EnvironmentConfig.supabaseAnonKey.count, 20,
                            "Anon key should be longer than 20 characters")
    }
}
```

**File 4:** Update `App/CoinFlipApp.swift`
```swift
import SwiftUI

@main
struct CoinFlipApp: App {
    init() {
        // Initialize Supabase
        _ = SupabaseService.shared

        // Configure for onboarding
        do {
            try AWSConfig.shared.configure()
        } catch {
            print("❌ Failed to configure: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### Test Execution
```bash
# Run tests
xcodebuild test -scheme CoinFlip -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd+U

# Expected results:
# ✅ testSupabaseClientInitialization - PASSED
# ✅ testSupabaseURLConfiguration - PASSED
# ✅ testSupabaseKeyConfiguration - PASSED
```

#### Completion Checklist
- [ ] Supabase project created
- [ ] SDK installed via SPM
- [ ] SupabaseService.swift created
- [ ] EnvironmentConfig.swift created with your credentials
- [ ] All 3 tests passing
- [ ] Console shows "✅ Supabase initialized" on app launch

#### Commit & Tag
```bash
git add .
git commit -m "Task 11.1: Supabase project setup complete"
git tag sprint-11-task-1-complete
git push origin feature/sprint-11-task-1-supabase-setup --tags
```

---

### Task 11.2: Database Schema Design

**Branch:** `feature/sprint-11-task-2-database-schema`

#### Prompt to Execute
```
Execute Task 11.2: Database Schema Design

Steps:
1. Create SQL schema for users, portfolios, holdings, transactions tables
2. Execute SQL in Supabase SQL Editor
3. Set up Row Level Security (RLS) policies
4. Create database indexes for performance
5. Create Swift models matching database schema
6. Write tests to verify schema structure

Acceptance Criteria:
- All 4 tables created in Supabase
- RLS policies enabled and tested
- Indexes created for foreign keys
- Swift models match database schema
- Models conform to Codable, Identifiable, Equatable

Files to Create:
- Database/schema.sql (for documentation)
- Models/User.swift (update existing)
- Models/Portfolio.swift (update existing)
- Models/Holding.swift (update existing)
- Models/Transaction.swift (update existing)
- Tests/Unit/ModelTests.swift

Tests Required:
1. testUserModelCodable() - Verify User can encode/decode
2. testPortfolioModelCodable() - Verify Portfolio serialization
3. testHoldingModelEquatable() - Verify equality comparison
4. testTransactionModelCodable() - Verify Transaction serialization
```

#### SQL Schema

**File:** `Database/schema.sql`
```sql
-- ==============================================
-- CoinFlip Database Schema
-- ==============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- USERS TABLE
-- ==============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_emoji TEXT DEFAULT '🚀',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for username lookup
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = auth_user_id);

-- ==============================================
-- PORTFOLIOS TABLE
-- ==============================================
CREATE TABLE portfolios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cash_balance DECIMAL(20, 8) DEFAULT 1000.00,
  starting_balance DECIMAL(20, 8) DEFAULT 1000.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for user lookup
CREATE INDEX idx_portfolios_user_id ON portfolios(user_id);

-- RLS Policies
ALTER TABLE portfolios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own portfolio"
  ON portfolios FOR SELECT
  USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own portfolio"
  ON portfolios FOR UPDATE
  USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own portfolio"
  ON portfolios FOR INSERT
  WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ==============================================
-- HOLDINGS TABLE
-- ==============================================
CREATE TABLE holdings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  portfolio_id UUID NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
  coin_id TEXT NOT NULL,
  coin_symbol TEXT NOT NULL,
  coin_name TEXT NOT NULL,
  quantity DECIMAL(20, 8) NOT NULL CHECK (quantity >= 0),
  average_buy_price DECIMAL(20, 8) NOT NULL CHECK (average_buy_price >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(portfolio_id, coin_id)
);

-- Indexes
CREATE INDEX idx_holdings_portfolio_id ON holdings(portfolio_id);
CREATE INDEX idx_holdings_coin_id ON holdings(coin_id);

-- RLS Policies
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own holdings"
  ON holdings FOR SELECT
  USING (portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  ));

CREATE POLICY "Users can manage own holdings"
  ON holdings FOR ALL
  USING (portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  ));

-- ==============================================
-- TRANSACTIONS TABLE
-- ==============================================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  portfolio_id UUID NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
  coin_id TEXT NOT NULL,
  coin_symbol TEXT NOT NULL,
  coin_name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('buy', 'sell')),
  quantity DECIMAL(20, 8) NOT NULL CHECK (quantity > 0),
  price_per_coin DECIMAL(20, 8) NOT NULL CHECK (price_per_coin >= 0),
  total_value DECIMAL(20, 8) NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_transactions_portfolio_id ON transactions(portfolio_id);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp DESC);
CREATE INDEX idx_transactions_type ON transactions(type);

-- RLS Policies
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  ));

CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  ));

-- ==============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ==============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portfolios_updated_at
  BEFORE UPDATE ON portfolios
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_holdings_updated_at
  BEFORE UPDATE ON holdings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================
-- Run these to verify setup:
-- SELECT * FROM users;
-- SELECT * FROM portfolios;
-- SELECT * FROM holdings;
-- SELECT * FROM transactions;
```

#### Execution Steps
1. Open Supabase Dashboard → SQL Editor
2. Copy entire `schema.sql` contents
3. Click "Run" to execute
4. Verify tables appear in Table Editor

#### Updated Models

**File:** `Models/User.swift` (Update)
```swift
import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let authUserId: UUID
    var username: String
    var avatarEmoji: String
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case username
        case avatarEmoji = "avatar_emoji"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**File:** `Models/Portfolio.swift` (Update - add Codable keys)
```swift
import Foundation

struct Portfolio: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var cashBalance: Double
    var holdings: [Holding]
    var transactions: [Transaction]
    let startingBalance: Double
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cashBalance = "cash_balance"
        case startingBalance = "starting_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // holdings and transactions loaded separately
    }

    // ... keep existing methods
}
```

**File:** `Models/Holding.swift` (Update)
```swift
import Foundation

struct Holding: Codable, Identifiable, Equatable {
    let id: UUID
    let portfolioId: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    var quantity: Double
    var averageBuyPrice: Double
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case coinId = "coin_id"
        case coinSymbol = "coin_symbol"
        case coinName = "coin_name"
        case quantity
        case averageBuyPrice = "average_buy_price"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Keep existing init from Coin
    init(coin: Coin, quantity: Double, buyPrice: Double) {
        self.id = UUID()
        self.portfolioId = UUID() // Will be set when saving
        self.coinId = coin.id
        self.coinSymbol = coin.symbol
        self.coinName = coin.name
        self.quantity = quantity
        self.averageBuyPrice = buyPrice
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**File:** `Models/Transaction.swift` (Update)
```swift
import Foundation

enum TransactionType: String, Codable {
    case buy
    case sell
}

struct Transaction: Codable, Identifiable, Equatable {
    let id: UUID
    let portfolioId: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let type: TransactionType
    let quantity: Double
    let pricePerCoin: Double
    let totalValue: Double
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case coinId = "coin_id"
        case coinSymbol = "coin_symbol"
        case coinName = "coin_name"
        case type
        case quantity
        case pricePerCoin = "price_per_coin"
        case totalValue = "total_value"
        case timestamp
    }

    // Keep existing init from Coin
    init(coin: Coin, type: TransactionType, quantity: Double, pricePerCoin: Double, portfolioId: UUID) {
        self.id = UUID()
        self.portfolioId = portfolioId
        self.coinId = coin.id
        self.coinSymbol = coin.symbol
        self.coinName = coin.name
        self.type = type
        self.quantity = quantity
        self.pricePerCoin = pricePerCoin
        self.totalValue = quantity * pricePerCoin
        self.timestamp = Date()
    }
}
```

#### Unit Tests

**File:** `Tests/Unit/ModelTests.swift`
```swift
import XCTest
@testable import CoinFlip

class ModelTests: XCTestCase {

    // MARK: - User Tests

    func testUserModelCodable() throws {
        let user = User(
            id: UUID(),
            authUserId: UUID(),
            username: "testuser",
            avatarEmoji: "🚀",
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)

        XCTAssertEqual(user.id, decodedUser.id)
        XCTAssertEqual(user.username, decodedUser.username)
        XCTAssertEqual(user.avatarEmoji, decodedUser.avatarEmoji)
    }

    // MARK: - Portfolio Tests

    func testPortfolioModelCodable() throws {
        let portfolio = Portfolio(
            id: UUID(),
            userId: UUID(),
            cashBalance: 1000,
            holdings: [],
            transactions: [],
            startingBalance: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(portfolio)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(Portfolio.self, from: data)

        XCTAssertEqual(portfolio.id, decoded.id)
        XCTAssertEqual(portfolio.cashBalance, decoded.cashBalance)
    }

    func testPortfolioTotalValue() {
        var portfolio = Portfolio(startingBalance: 1000)
        portfolio.cashBalance = 500

        let holding1 = Holding(
            coin: MockData.coins[0],
            quantity: 100,
            buyPrice: 1.0
        )
        portfolio.holdings = [holding1]

        let prices = ["dogecoin": 1.5]
        let totalValue = portfolio.totalValue(prices: prices)

        // Cash: 500 + Holding: 100 * 1.5 = 650
        XCTAssertEqual(totalValue, 650)
    }

    // MARK: - Holding Tests

    func testHoldingModelEquatable() {
        let holding1 = Holding(
            coin: MockData.coins[0],
            quantity: 100,
            buyPrice: 1.0
        )

        var holding2 = holding1
        holding2.quantity = 100

        XCTAssertEqual(holding1.id, holding2.id)
    }

    func testHoldingInitFromCoin() {
        let coin = MockData.coins[0]
        let holding = Holding(coin: coin, quantity: 50, buyPrice: 0.5)

        XCTAssertEqual(holding.coinId, coin.id)
        XCTAssertEqual(holding.coinSymbol, coin.symbol)
        XCTAssertEqual(holding.quantity, 50)
        XCTAssertEqual(holding.averageBuyPrice, 0.5)
    }

    // MARK: - Transaction Tests

    func testTransactionModelCodable() throws {
        let transaction = Transaction(
            coin: MockData.coins[0],
            type: .buy,
            quantity: 100,
            pricePerCoin: 1.0,
            portfolioId: UUID()
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(transaction)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Transaction.self, from: data)

        XCTAssertEqual(transaction.id, decoded.id)
        XCTAssertEqual(transaction.type, decoded.type)
        XCTAssertEqual(transaction.quantity, decoded.quantity)
    }

    func testTransactionTotalValueCalculation() {
        let transaction = Transaction(
            coin: MockData.coins[0],
            type: .buy,
            quantity: 100,
            pricePerCoin: 1.5,
            portfolioId: UUID()
        )

        XCTAssertEqual(transaction.totalValue, 150.0)
    }

    func testTransactionTypes() {
        XCTAssertEqual(TransactionType.buy.rawValue, "buy")
        XCTAssertEqual(TransactionType.sell.rawValue, "sell")
    }
}
```

#### Test Execution
```bash
# Run model tests
xcodebuild test \
  -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CoinFlipTests/ModelTests

# Expected: All 8 tests pass
```

#### Completion Checklist
- [ ] SQL schema executed in Supabase
- [ ] All 4 tables visible in Supabase Table Editor
- [ ] RLS policies enabled (lock icon showing)
- [ ] All models updated with Codable keys
- [ ] All 8 model tests passing
- [ ] schema.sql saved to /Database folder

#### Commit & Tag
```bash
git add .
git commit -m "Task 11.2: Database schema and models complete"
git tag sprint-11-task-2-complete
git push origin feature/sprint-11-task-2-database-schema --tags
```

---

### Task 11.3: Service Layer Implementation

**Branch:** `feature/sprint-11-task-3-service-layer`

#### Prompt to Execute
```
Execute Task 11.3: Service Layer Implementation

Steps:
1. Create protocol-based service layer (DataServiceProtocol)
2. Implement MockDataService for offline dev/testing
3. Implement SupabaseDataService for real API calls
4. Create DataServiceFactory with feature flag
5. Add developer settings to toggle between mock/real API
6. Write unit tests for both service implementations
7. Write integration tests for service factory

Acceptance Criteria:
- DataServiceProtocol defined with all CRUD methods
- MockDataService fully implements protocol (in-memory storage)
- SupabaseDataService fully implements protocol (real API calls)
- Feature flag allows switching between services
- Developer settings panel in Profile tab
- All services tested independently
- Factory tested for correct service instantiation

Files to Create:
- Services/DataServiceProtocol.swift
- Services/MockDataService.swift
- Services/SupabaseDataService.swift
- Services/DataServiceFactory.swift
- Features/Profile/Views/DeveloperSettingsView.swift
- Tests/Unit/MockDataServiceTests.swift
- Tests/Unit/SupabaseDataServiceTests.swift
- Tests/Unit/DataServiceFactoryTests.swift
- Tests/Integration/ServiceIntegrationTests.swift

Tests Required:
1. Mock service CRUD tests (8 tests)
2. Supabase service tests (8 tests)
3. Factory tests (2 tests)
4. Integration tests (4 tests)
```

#### Implementation Files

**File 1:** `Services/DataServiceProtocol.swift`
```swift
import Foundation

/// Protocol defining all backend data operations
/// Can be implemented by MockDataService or SupabaseDataService
protocol DataServiceProtocol {
    // User Operations
    func createUser(authUserId: UUID, username: String, avatarEmoji: String) async throws -> User
    func fetchUser(authUserId: UUID) async throws -> User?
    func updateUser(_ user: User) async throws

    // Portfolio Operations
    func createPortfolio(userId: UUID) async throws -> Portfolio
    func fetchPortfolio(userId: UUID) async throws -> Portfolio?
    func updateCashBalance(portfolioId: UUID, amount: Double) async throws

    // Holdings Operations
    func fetchHoldings(portfolioId: UUID) async throws -> [Holding]
    func createHolding(_ holding: Holding) async throws
    func updateHolding(_ holding: Holding) async throws
    func deleteHolding(id: UUID) async throws

    // Transaction Operations
    func fetchTransactions(portfolioId: UUID, limit: Int?) async throws -> [Transaction]
    func createTransaction(_ transaction: Transaction) async throws
}
```

**File 2:** `Services/MockDataService.swift`
```swift
import Foundation

/// Mock service for offline development and testing
/// Stores data in memory, perfect for UI development
class MockDataService: DataServiceProtocol {
    // In-memory storage
    private var users: [UUID: User] = [:]
    private var portfolios: [UUID: Portfolio] = [:]
    private var holdings: [UUID: [Holding]] = [:]
    private var transactions: [UUID: [Transaction]] = [:]

    // MARK: - User Operations

    func createUser(authUserId: UUID, username: String, avatarEmoji: String) async throws -> User {
        let user = User(
            id: UUID(),
            authUserId: authUserId,
            username: username,
            avatarEmoji: avatarEmoji,
            createdAt: Date(),
            updatedAt: Date()
        )
        users[authUserId] = user
        return user
    }

    func fetchUser(authUserId: UUID) async throws -> User? {
        return users[authUserId]
    }

    func updateUser(_ user: User) async throws {
        users[user.authUserId] = user
    }

    // MARK: - Portfolio Operations

    func createPortfolio(userId: UUID) async throws -> Portfolio {
        let portfolio = Portfolio(
            id: UUID(),
            userId: userId,
            cashBalance: 1000,
            holdings: [],
            transactions: [],
            startingBalance: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )
        portfolios[userId] = portfolio
        return portfolio
    }

    func fetchPortfolio(userId: UUID) async throws -> Portfolio? {
        return portfolios[userId]
    }

    func updateCashBalance(portfolioId: UUID, amount: Double) async throws {
        for (userId, var portfolio) in portfolios {
            if portfolio.id == portfolioId {
                portfolio.cashBalance = amount
                portfolio.updatedAt = Date()
                portfolios[userId] = portfolio
                break
            }
        }
    }

    // MARK: - Holdings Operations

    func fetchHoldings(portfolioId: UUID) async throws -> [Holding] {
        return holdings[portfolioId] ?? []
    }

    func createHolding(_ holding: Holding) async throws {
        var portfolioHoldings = holdings[holding.portfolioId] ?? []
        portfolioHoldings.append(holding)
        holdings[holding.portfolioId] = portfolioHoldings
    }

    func updateHolding(_ holding: Holding) async throws {
        var portfolioHoldings = holdings[holding.portfolioId] ?? []
        if let index = portfolioHoldings.firstIndex(where: { $0.id == holding.id }) {
            portfolioHoldings[index] = holding
            holdings[holding.portfolioId] = portfolioHoldings
        }
    }

    func deleteHolding(id: UUID) async throws {
        for (portfolioId, var portfolioHoldings) in holdings {
            if let index = portfolioHoldings.firstIndex(where: { $0.id == id }) {
                portfolioHoldings.remove(at: index)
                holdings[portfolioId] = portfolioHoldings
                break
            }
        }
    }

    // MARK: - Transaction Operations

    func fetchTransactions(portfolioId: UUID, limit: Int? = nil) async throws -> [Transaction] {
        var txns = transactions[portfolioId] ?? []
        txns.sort { $0.timestamp > $1.timestamp }
        if let limit = limit {
            return Array(txns.prefix(limit))
        }
        return txns
    }

    func createTransaction(_ transaction: Transaction) async throws {
        var portfolioTransactions = transactions[transaction.portfolioId] ?? []
        portfolioTransactions.append(transaction)
        transactions[transaction.portfolioId] = portfolioTransactions
    }

    // MARK: - Test Helpers

    /// Reset all data (useful for tests)
    func reset() {
        users.removeAll()
        portfolios.removeAll()
        holdings.removeAll()
        transactions.removeAll()
    }
}
```

**File 3:** `Services/SupabaseDataService.swift`
```swift
import Foundation
import Supabase

/// Real backend service using Supabase
class SupabaseDataService: DataServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseService.shared.client) {
        self.client = client
    }

    // MARK: - User Operations

    func createUser(authUserId: UUID, username: String, avatarEmoji: String) async throws -> User {
        let user = User(
            id: UUID(),
            authUserId: authUserId,
            username: username,
            avatarEmoji: avatarEmoji,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await client
            .from("users")
            .insert(user)
            .execute()

        return user
    }

    func fetchUser(authUserId: UUID) async throws -> User? {
        let response = try await client
            .from("users")
            .select()
            .eq("auth_user_id", value: authUserId.uuidString)
            .single()
            .execute()

        return try? JSONDecoder().decode(User.self, from: response.data)
    }

    func updateUser(_ user: User) async throws {
        try await client
            .from("users")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .execute()
    }

    // MARK: - Portfolio Operations

    func createPortfolio(userId: UUID) async throws -> Portfolio {
        let portfolio = Portfolio(
            id: UUID(),
            userId: userId,
            cashBalance: 1000,
            holdings: [],
            transactions: [],
            startingBalance: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await client
            .from("portfolios")
            .insert(portfolio)
            .execute()

        return portfolio
    }

    func fetchPortfolio(userId: UUID) async throws -> Portfolio? {
        let response = try await client
            .from("portfolios")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        return try? JSONDecoder().decode(Portfolio.self, from: response.data)
    }

    func updateCashBalance(portfolioId: UUID, amount: Double) async throws {
        try await client
            .from("portfolios")
            .update(["cash_balance": amount, "updated_at": Date()])
            .eq("id", value: portfolioId.uuidString)
            .execute()
    }

    // MARK: - Holdings Operations

    func fetchHoldings(portfolioId: UUID) async throws -> [Holding] {
        let response = try await client
            .from("holdings")
            .select()
            .eq("portfolio_id", value: portfolioId.uuidString)
            .execute()

        return try JSONDecoder().decode([Holding].self, from: response.data)
    }

    func createHolding(_ holding: Holding) async throws {
        try await client
            .from("holdings")
            .insert(holding)
            .execute()
    }

    func updateHolding(_ holding: Holding) async throws {
        try await client
            .from("holdings")
            .update(holding)
            .eq("id", value: holding.id.uuidString)
            .execute()
    }

    func deleteHolding(id: UUID) async throws {
        try await client
            .from("holdings")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Transaction Operations

    func fetchTransactions(portfolioId: UUID, limit: Int? = nil) async throws -> [Transaction] {
        var query = client
            .from("transactions")
            .select()
            .eq("portfolio_id", value: portfolioId.uuidString)
            .order("timestamp", ascending: false)

        if let limit = limit {
            query = query.limit(limit)
        }

        let response = try await query.execute()
        return try JSONDecoder().decode([Transaction].self, from: response.data)
    }

    func createTransaction(_ transaction: Transaction) async throws {
        try await client
            .from("transactions")
            .insert(transaction)
            .execute()
    }
}
```

**File 4:** `Services/DataServiceFactory.swift`
```swift
import Foundation

enum DataServiceMode: String, Codable, CaseIterable {
    case mock = "Mock Data"
    case api = "Live API"
}

class DataServiceFactory {
    static let shared = DataServiceFactory()

    @UserDefaultsBacked(key: "data_service_mode", defaultValue: .mock)
    var mode: DataServiceMode

    private var mockService: MockDataService?
    private var apiService: SupabaseDataService?

    func makeService() -> DataServiceProtocol {
        switch mode {
        case .mock:
            if mockService == nil {
                mockService = MockDataService()
            }
            return mockService!
        case .api:
            if apiService == nil {
                apiService = SupabaseDataService()
            }
            return apiService!
        }
    }

    /// Reset services (useful for testing)
    func reset() {
        mockService = nil
        apiService = nil
    }
}

// MARK: - UserDefaults Property Wrapper

@propertyWrapper
struct UserDefaultsBacked<T: Codable> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
```

**File 5:** `Features/Profile/Views/DeveloperSettingsView.swift`
```swift
import SwiftUI

struct DeveloperSettingsView: View {
    @State private var dataServiceMode: DataServiceMode
    @State private var showResetAlert = false

    init() {
        _dataServiceMode = State(initialValue: DataServiceFactory.shared.mode)
    }

    var body: some View {
        Form {
            Section(header: Text("Data Source")) {
                Picker("Service Mode", selection: $dataServiceMode) {
                    ForEach(DataServiceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .onChange(of: dataServiceMode) { _, newValue in
                    DataServiceFactory.shared.mode = newValue
                    DataServiceFactory.shared.reset()
                    HapticManager.shared.success()
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Current: \(dataServiceMode.rawValue)")
                        .font(.caption)
                        .foregroundColor(.primaryGreen)

                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Section(header: Text("Testing")) {
                Button("Reset Mock Data") {
                    showResetAlert = true
                }
                .foregroundColor(.lossRed)

                Button("Clear All Cache") {
                    UserDefaults.standard.removePersistentDomain(
                        forName: Bundle.main.bundleIdentifier!
                    )
                    HapticManager.shared.success()
                }
            }

            Section(header: Text("Build Info")) {
                LabeledContent("Environment", value: environmentName)
                LabeledContent("Build", value: Bundle.main.buildNumber)
                LabeledContent("Version", value: Bundle.main.versionNumber)
                LabeledContent("Supabase", value: supabaseStatus)
            }
        }
        .navigationTitle("Developer Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Mock Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                if case .mock = dataServiceMode {
                    // Reset mock service
                    DataServiceFactory.shared.reset()
                    HapticManager.shared.success()
                }
            }
        } message: {
            Text("This will clear all mock data from memory.")
        }
    }

    private var modeDescription: String {
        switch dataServiceMode {
        case .mock:
            return "Using in-memory mock data. Changes won't persist."
        case .api:
            return "Using live Supabase API. Data persists to cloud."
        }
    }

    private var environmentName: String {
        #if DEBUG
        return "Development"
        #else
        return "Production"
        #endif
    }

    private var supabaseStatus: String {
        let url = EnvironmentConfig.supabaseURL
        return url.contains("supabase.co") ? "Connected" : "Not Configured"
    }
}

extension Bundle {
    var versionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
```

**File 6:** Update `Features/Profile/Views/ProfileView.swift`
```swift
// Add after "About" section and before "Account Actions"

#if DEBUG
// Developer Settings
VStack(alignment: .leading, spacing: Spacing.sm) {
    Text("Developer")
        .font(.headline3)
        .foregroundColor(.textPrimary)
        .padding(.horizontal, Spacing.xs)

    NavigationLink {
        DeveloperSettingsView()
    } label: {
        SettingsRow(
            icon: "hammer.fill",
            title: "Developer Settings",
            subtitle: "Toggle mock/API, reset data",
            iconColor: .orange
        ) {}
    }
}
#endif
```

#### Unit Tests

**Remaining tests content will continue in next section due to length...**

#### Completion Checklist
- [ ] All service files created
- [ ] Developer settings added to Profile
- [ ] Feature flag working (can toggle in app)
- [ ] All unit tests passing
- [ ] Integration tests passing

#### Commit & Tag
```bash
git add .
git commit -m "Task 11.3: Service layer with mock/API toggle complete"
git tag sprint-11-task-3-complete
git push origin feature/sprint-11-task-3-service-layer --tags
```

---

### Task 11.4: Sprint 11 Testing & Merge

**Branch:** `feature/sprint-11-task-4-tests`

#### Prompt to Execute
```
Execute Task 11.4: Sprint 11 Final Testing and Merge

Steps:
1. Run all unit tests and verify 100% pass rate
2. Run integration tests
3. Manually test feature flag toggle in app
4. Verify mock service works offline
5. Generate test coverage report (target: >80%)
6. Create Sprint 11 summary document
7. Merge all task branches into sprint branch
8. Merge sprint branch to develop
9. Tag sprint as complete

Acceptance Criteria:
- All unit tests pass (30+ tests)
- All integration tests pass
- Test coverage >80%
- Feature flag works in app
- Mock service functional
- No regressions in existing features
- Sprint 11 merged to develop
- Tagged as sprint-11-complete

Tests to Run:
- SupabaseServiceTests
- ModelTests
- MockDataServiceTests
- DataServiceFactoryTests
- ServiceIntegrationTests

Manual Testing:
1. Launch app
2. Navigate to Profile → Developer Settings
3. Toggle between Mock/API modes
4. Verify mode changes
5. Test existing features still work
```

#### Test Execution Commands

```bash
# Run all tests
xcodebuild test \
  -scheme CoinFlip \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# Generate coverage report
xcrun xccov view --report \
  ~/Library/Developer/Xcode/DerivedData/CoinFlip-*/Logs/Test/*.xcresult

# Run specific test suites
xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/SupabaseServiceTests

xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/ModelTests

xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/MockDataServiceTests
```

#### Sprint Summary Document

**File:** `Documentation/Sprint-11-Summary.md`
```markdown
# Sprint 11: Backend Foundation - Complete ✅

**Completed:** [Date]
**Duration:** X days

## Overview
Successfully set up Supabase backend with database schema, service layer, and testing infrastructure.

## Tasks Completed

### Task 11.1: Supabase Setup ✅
- Created Supabase project
- Installed Swift SDK
- Configured environment
- Tests: 3/3 passing

### Task 11.2: Database Schema ✅
- Created 4 tables (users, portfolios, holdings, transactions)
- Implemented RLS policies
- Updated Swift models
- Tests: 8/8 passing

### Task 11.3: Service Layer ✅
- Created DataServiceProtocol
- Implemented MockDataService
- Implemented SupabaseDataService
- Created feature flag system
- Added developer settings
- Tests: 15/15 passing

### Task 11.4: Testing & Integration ✅
- All unit tests passing
- Integration tests passing
- Test coverage: 85%
- Feature flag verified working

## Git Tags
- `sprint-11-task-1-complete`
- `sprint-11-task-2-complete`
- `sprint-11-task-3-complete`
- `sprint-11-complete`

## Rollback Commands
```bash
# Rollback to before Sprint 11
git checkout sprint-10-complete

# Rollback to specific task
git checkout sprint-11-task-2-complete
```

## What's Working
- ✅ Supabase client initialized
- ✅ Database schema deployed
- ✅ Mock service fully functional
- ✅ API service structure complete
- ✅ Feature flag for switching modes
- ✅ Developer settings panel
- ✅ All existing features still work

## What's Next (Sprint 12)
- User authentication with Supabase Auth
- Passkey integration
- Login/Signup UI
- Session management

## Test Results
```
Total Tests: 26
Passed: 26
Failed: 0
Coverage: 85%
```

## Known Issues
None

## Dependencies Added
- Supabase Swift SDK (2.0+)
```

#### Merge Commands

```bash
# Ensure you're on sprint branch
git checkout feature/sprint-11-backend-foundation

# Merge all task branches
git merge feature/sprint-11-task-1-supabase-setup
git merge feature/sprint-11-task-2-database-schema
git merge feature/sprint-11-task-3-service-layer

# Run final tests
xcodebuild test -scheme CoinFlip

# If all pass, merge to develop
git checkout develop
git merge feature/sprint-11-backend-foundation

# Tag as complete
git tag -a sprint-11-complete -m "Sprint 11: Backend foundation complete"
git push origin develop --tags

# Delete task branches (optional)
git branch -d feature/sprint-11-task-1-supabase-setup
git branch -d feature/sprint-11-task-2-database-schema
git branch -d feature/sprint-11-task-3-service-layer
```

#### Completion Checklist
- [ ] All 26+ tests passing
- [ ] Test coverage >80%
- [ ] Feature flag tested in app
- [ ] Mock mode works
- [ ] No regressions
- [ ] Sprint summary created
- [ ] All branches merged
- [ ] Tagged sprint-11-complete
- [ ] Pushed to origin

---

## Sprint 11 Complete! 🎉

You can now:
1. Start Sprint 12 (Authentication)
2. Continue developing with mock data
3. Rollback if needed using tags

**Next Sprint Preview:**
```bash
git checkout -b feature/sprint-12-authentication
```

Sprint 12 will add user authentication and allow real backend usage.
