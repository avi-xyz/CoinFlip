import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeService = ThemeService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var portfolioViewModel: PortfolioViewModel
    @StateObject private var leaderboardViewModel: LeaderboardViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    init() {
        let portfolio = MockData.emptyPortfolio
        let homeVM = HomeViewModel(portfolio: portfolio)
        let portfolioVM = PortfolioViewModel(portfolio: portfolio, coins: [])
        let leaderboardVM = LeaderboardViewModel()
        let profileVM = ProfileViewModel()

        _homeViewModel = StateObject(wrappedValue: homeVM)
        _portfolioViewModel = StateObject(wrappedValue: portfolioVM)
        _leaderboardViewModel = StateObject(wrappedValue: leaderboardVM)
        _profileViewModel = StateObject(wrappedValue: profileVM)
    }

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                LoadingView()

            case .needsUsername:
                UsernameSetupView()

            case .authenticated:
                mainAppView

            case .unauthenticated:
                LoadingView()
                    .onAppear {
                        // Auto sign in anonymously when unauthenticated
                        Task {
                            try? await authService.signInAnonymously()
                        }
                    }
            }
        }
        .preferredColorScheme(themeService.currentTheme.colorScheme)
    }

    private var mainAppView: some View {
        ZStack {
            TabView {
                HomeViewTab(viewModel: homeViewModel, portfolioViewModel: portfolioViewModel, leaderboardViewModel: leaderboardViewModel, profileViewModel: profileViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                ViralCoinsView()
                    .environmentObject(homeViewModel)
                    .tabItem {
                        Label("Viral", systemImage: "flame.fill")
                    }

                PortfolioViewTab(viewModel: portfolioViewModel, homeViewModel: homeViewModel, leaderboardViewModel: leaderboardViewModel)
                    .tabItem {
                        Label("Portfolio", systemImage: "chart.pie.fill")
                    }
                    .badge(portfolioViewModel.holdings.count > 0 ? portfolioViewModel.holdings.count : 0)

                LeaderboardView()
                    .environmentObject(leaderboardViewModel)
                    .tabItem {
                        Label("Leaderboard", systemImage: "trophy.fill")
                    }

                ProfileView()
                    .environmentObject(profileViewModel)
                    .environmentObject(authService)
                    .environmentObject(themeService)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .accentColor(.primaryGreen)
            .environmentObject(networkMonitor)
            .onAppear {
                setupProfileCallbacks()

                // Show onboarding on first launch if authenticated
                if !hasCompletedOnboarding && authService.authState.isAuthenticated {
                    showOnboarding = true
                }
            }

            // Offline banner at top
            VStack {
                OfflineBanner()
                    .environmentObject(networkMonitor)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .preferredColorScheme(themeService.currentTheme.colorScheme)
                .onDisappear {
                    hasCompletedOnboarding = true
                }
        }
    }

    private func setupProfileCallbacks() {
        profileViewModel.onResetPortfolio = {
            // Reset portfolio in database and update local state
            Task {
                await homeViewModel.resetPortfolio()

                // Sync to portfolio view model
                await MainActor.run {
                    portfolioViewModel.portfolio = homeViewModel.portfolio
                    portfolioViewModel.coins = homeViewModel.trendingCoins
                    portfolioViewModel.currentPrices = homeViewModel.currentPrices
                }
            }
        }
    }
}

// Wrapper for HomeView to share view models
struct HomeViewTab: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @ObservedObject var leaderboardViewModel: LeaderboardViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        HomeView()
            .environmentObject(viewModel)
            .onAppear {
                syncData()
            }
            .onChange(of: viewModel.portfolio.cashBalance) { _, _ in
                syncData()
            }
            .onChange(of: viewModel.portfolio.holdings) { _, _ in
                syncData()
            }
            .onChange(of: viewModel.netWorth) { _, _ in
                syncData()
            }
    }

    private func syncData() {
        print("🔄 HomeViewTab.syncData() - START")
        print("   📊 BEFORE sync:")
        print("      Home: cash=$\(viewModel.portfolio.cashBalance), holdings=\(viewModel.portfolio.holdings.count), netWorth=$\(viewModel.netWorth)")
        print("      Portfolio: cash=$\(portfolioViewModel.portfolio.cashBalance), holdings=\(portfolioViewModel.portfolio.holdings.count)")
        print("      Home currentPrices count: \(viewModel.currentPrices.count)")
        print("      Portfolio currentPrices count: \(portfolioViewModel.currentPrices.count)")

        portfolioViewModel.portfolio = viewModel.portfolio
        portfolioViewModel.coins = viewModel.trendingCoins
        portfolioViewModel.currentPrices = viewModel.currentPrices

        print("   📊 AFTER sync:")
        print("      Portfolio currentPrices count: \(portfolioViewModel.currentPrices.count)")
        if !viewModel.currentPrices.isEmpty {
            print("      Synced prices: \(viewModel.currentPrices.keys.joined(separator: ", "))")
        }
        print("      💰 Home net worth: $\(viewModel.netWorth)")
        print("      💼 Portfolio net worth: $\(portfolioViewModel.portfolio.cashBalance + portfolioViewModel.totalHoldingsValue)")
        print("      📊 Holdings count: \(portfolioViewModel.holdings.count)")
        print("      💵 Cash: $\(portfolioViewModel.portfolio.cashBalance)")
        print("      💎 Holdings value: $\(portfolioViewModel.totalHoldingsValue)")

        let gain = viewModel.dailyChangePercentage
        leaderboardViewModel.updateUserStats(netWorth: viewModel.netWorth, gain: gain)

        if let currentUser = leaderboardViewModel.currentUserEntry {
            profileViewModel.updateStats(netWorth: viewModel.netWorth, rank: currentUser.rank, gainPercentage: gain)
        }
    }
}

// Wrapper for PortfolioView to share view models
struct PortfolioViewTab: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var leaderboardViewModel: LeaderboardViewModel

    var body: some View {
        PortfolioView()
            .environmentObject(viewModel)
            .onAppear {
                syncData()
            }
            .onChange(of: viewModel.portfolio.cashBalance) { _, _ in
                syncData()
            }
            .onChange(of: viewModel.portfolio.holdings) { _, _ in
                syncData()
            }
    }

    private func syncData() {
        print("🔄 PortfolioViewTab.syncData() - START")
        print("   📊 BEFORE sync:")
        print("      Portfolio: cash=$\(viewModel.portfolio.cashBalance), holdings=\(viewModel.portfolio.holdings.count), totalHoldingsValue=$\(viewModel.totalHoldingsValue)")
        print("      Home: cash=$\(homeViewModel.portfolio.cashBalance), holdings=\(homeViewModel.portfolio.holdings.count), netWorth=$\(homeViewModel.netWorth)")

        homeViewModel.portfolio = viewModel.portfolio
        Task {
            await homeViewModel.calculatePortfolioMetrics()

            let netWorth = homeViewModel.netWorth
            let gain = homeViewModel.dailyChangePercentage

            print("   📊 AFTER sync:")
            print("      Home: cash=$\(homeViewModel.portfolio.cashBalance), holdings=\(homeViewModel.portfolio.holdings.count)")
            print("      Home netWorth: $\(netWorth)")
            print("      Home dailyChange: $\(homeViewModel.dailyChange) (\(gain)%)")
            print("🔄 PortfolioViewTab.syncData() - END")

            leaderboardViewModel.updateUserStats(netWorth: netWorth, gain: gain)
        }
    }
}

#Preview { ContentView() }
