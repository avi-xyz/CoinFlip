import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = "You"
    @Published var avatarEmoji: String = "🚀"
    @Published var netWorth: Double = 1000
    @Published var rank: Int = 15
    @Published var totalGainPercentage: Double = 0

    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    var onResetPortfolio: (() -> Void)?

    init() {
        // Load user data from AuthService
        loadUserData()

        // Observe changes to currentUser
        authService.$currentUser
            .sink { [weak self] user in
                self?.loadUserData()
            }
            .store(in: &cancellables)
    }

    func loadUserData() {
        guard let user = authService.currentUser else { return }

        self.username = user.username
        self.avatarEmoji = user.avatarEmoji
    }

    func updateStats(netWorth: Double, rank: Int, gainPercentage: Double) {
        self.netWorth = netWorth
        self.rank = rank
        self.totalGainPercentage = gainPercentage
    }

    func resetPortfolio() {
        HapticManager.shared.success()
        onResetPortfolio?()
    }

    func signOut() async {
        do {
            try await authService.signOut()
            HapticManager.shared.success()
        } catch {
            print("❌ Error signing out: \(error)")
            HapticManager.shared.error()
        }
    }

    func updateAvatar(_ emoji: String) async {
        guard var user = authService.currentUser else { return }

        // Update local state immediately for UI responsiveness
        self.avatarEmoji = emoji

        // Save to backend
        user.avatarEmoji = emoji
        do {
            try await authService.updateUser(user)
            HapticManager.shared.success()
        } catch {
            print("❌ Error updating avatar: \(error)")
            HapticManager.shared.error()
        }
    }
}
