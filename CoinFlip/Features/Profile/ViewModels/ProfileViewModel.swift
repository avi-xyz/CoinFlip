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
        print("🔧 ProfileViewModel: Initializing...")

        // Load user data from AuthService
        loadUserData()

        // Observe changes to currentUser
        authService.$currentUser
            .sink { [weak self] user in
                print("🔧 ProfileViewModel: currentUser changed to: \(user?.username ?? "nil")")
                self?.loadUserData()
            }
            .store(in: &cancellables)
    }

    func loadUserData() {
        guard let user = authService.currentUser else {
            print("⚠️ ProfileViewModel: No currentUser in AuthService")
            return
        }

        print("✅ ProfileViewModel: Loading user data - Username: \(user.username), Avatar: \(user.avatarEmoji)")
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

    func updateUsername(_ newUsername: String) async throws {
        guard var user = authService.currentUser else {
            throw ProfileError.noUser
        }

        // Validate username
        guard !newUsername.isEmpty, newUsername.count >= 3, newUsername.count <= 20 else {
            throw ProfileError.invalidUsername
        }

        // Update local state immediately for UI responsiveness
        self.username = newUsername

        // Save to backend
        user.username = newUsername
        do {
            try await authService.updateUser(user)
            HapticManager.shared.success()
        } catch {
            // Revert local state on error
            self.username = authService.currentUser?.username ?? "You"
            throw error
        }
    }
}

enum ProfileError: LocalizedError {
    case noUser
    case invalidUsername

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "User not logged in"
        case .invalidUsername:
            return "Username must be between 3 and 20 characters"
        }
    }
}
