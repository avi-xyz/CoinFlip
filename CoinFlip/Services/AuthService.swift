//
//  AuthService.swift
//  CoinFlip
//
//  Created on Sprint 12
//  Anonymous Authentication Service
//

import Foundation
import Supabase
import Combine
import AuthenticationServices

/// Authentication state
enum AuthState: Equatable {
    case loading
    case authenticated(userId: UUID)
    case unauthenticated
    case needsUsername(userId: UUID)

    var isAuthenticated: Bool {
        switch self {
        case .authenticated, .needsUsername:
            return true
        case .loading, .unauthenticated:
            return false
        }
    }
}

/// Service for managing user authentication
///
/// Handles anonymous authentication, session management, and user account creation.
@MainActor
class AuthService: ObservableObject {

    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Published Properties

    @Published var authState: AuthState = .loading
    @Published var currentUser: User?
    @Published var error: String?

    // MARK: - Private Properties

    private let supabase: SupabaseClient
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        self.supabase = SupabaseService.shared.client
        self.dataService = DataServiceFactory.shared

        // Observe auth state changes
        observeAuthStateChanges()

        // Check for existing session
        Task {
            await checkSession()
        }
    }

    // MARK: - Public Methods

    /// Sign in anonymously
    /// Creates a new anonymous user account automatically
    func signInAnonymously() async throws {
        print("🔐 AuthService: Attempting anonymous sign in...")

        do {
            let session = try await supabase.auth.signInAnonymously()
            print("✅ AuthService: Anonymous sign in successful - User ID: \(session.user.id)")

            // Check if user exists in database
            await handleAuthenticatedUser(authUserId: session.user.id)

        } catch {
            print("❌ AuthService: Anonymous sign in failed - \(error.localizedDescription)")
            self.error = "Failed to sign in: \(error.localizedDescription)"
            self.authState = .unauthenticated
            throw error
        }
    }

    /// Sign out the current user
    func signOut() async throws {
        print("🔐 AuthService: Signing out...")

        do {
            try await supabase.auth.signOut()

            // Clear state
            self.currentUser = nil
            self.authState = .unauthenticated

            print("✅ AuthService: Sign out successful")

        } catch {
            print("❌ AuthService: Sign out failed - \(error.localizedDescription)")
            self.error = "Failed to sign out: \(error.localizedDescription)"
            throw error
        }
    }

    /// Create user profile with username
    /// Called after user picks their username
    func createUserProfile(username: String, avatarEmoji: String) async throws {
        guard case .needsUsername(let userId) = authState else {
            throw AuthServiceError.invalidState
        }

        print("👤 AuthService: Creating user profile for username: \(username)")

        do {
            // Create user in database
            let newUser = User(
                authUserId: userId,
                username: username,
                startingBalance: 1000,
                avatarEmoji: avatarEmoji
            )

            let createdUser = try await dataService.createUser(newUser)

            // Create portfolio for user
            _ = try await dataService.createPortfolio(
                userId: createdUser.id,
                startingBalance: 1000
            )

            // Update state
            self.currentUser = createdUser
            self.authState = .authenticated(userId: userId)

            print("✅ AuthService: User profile created successfully")
            print("   - Username: \(createdUser.username)")
            print("   - Avatar: \(createdUser.avatarEmoji)")
            print("   - currentUser is now set: \(self.currentUser != nil)")

        } catch {
            print("❌ AuthService: Failed to create user profile - \(error.localizedDescription)")
            self.error = "Failed to create profile: \(error.localizedDescription)"
            throw error
        }
    }

    /// Update current user
    func updateUser(_ user: User) async throws {
        print("👤 AuthService: Updating user profile...")

        do {
            let updatedUser = try await dataService.updateUser(user)
            self.currentUser = updatedUser

            print("✅ AuthService: User profile updated")

        } catch {
            print("❌ AuthService: Failed to update user - \(error.localizedDescription)")
            self.error = "Failed to update profile: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Private Methods

    /// Check for existing session on app launch
    private func checkSession() async {
        print("🔐 AuthService: Checking for existing session...")

        do {
            let session = try await supabase.auth.session
            print("✅ AuthService: Found existing session - User ID: \(session.user.id)")

            await handleAuthenticatedUser(authUserId: session.user.id)

        } catch {
            print("⚠️ AuthService: No existing session found")

            // Auto sign in anonymously
            do {
                try await signInAnonymously()
            } catch {
                print("❌ AuthService: Auto sign in failed - \(error.localizedDescription)")
                self.authState = .unauthenticated
            }
        }
    }

    /// Handle authenticated user - check if they have a profile
    private func handleAuthenticatedUser(authUserId: UUID) async {
        do {
            // Try to fetch user from database
            if let user = try await dataService.fetchUser() {
                // User exists, fully authenticated
                self.currentUser = user
                self.authState = .authenticated(userId: authUserId)
                print("✅ AuthService: User profile found - \(user.username)")
                print("   - Avatar: \(user.avatarEmoji)")
                print("   - currentUser is now set: \(self.currentUser != nil)")
            } else {
                // User authenticated but no profile (needs username)
                self.authState = .needsUsername(userId: authUserId)
                print("⚠️ AuthService: User needs to create profile")
            }
        } catch {
            // Error fetching user, assume needs username
            print("⚠️ AuthService: Error fetching user, assuming needs profile - \(error.localizedDescription)")
            self.authState = .needsUsername(userId: authUserId)
        }
    }

    /// Observe auth state changes from Supabase
    private func observeAuthStateChanges() {
        Task {
            for await state in await supabase.auth.authStateChanges {
                await handleAuthStateChange(event: state.event, session: state.session)
            }
        }
    }

    /// Handle auth state change events
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        print("🔐 AuthService: Auth state changed - Event: \(event)")

        switch event {
        case .signedIn:
            if let session = session {
                await handleAuthenticatedUser(authUserId: session.user.id)
            }

        case .signedOut:
            self.currentUser = nil
            self.authState = .unauthenticated

        case .tokenRefreshed:
            print("🔄 AuthService: Token refreshed")

        case .userUpdated:
            print("👤 AuthService: User updated")

        case .passwordRecovery:
            break

        case .userDeleted:
            self.currentUser = nil
            self.authState = .unauthenticated

        @unknown default:
            break
        }
    }
}

// MARK: - Errors

enum AuthServiceError: LocalizedError {
    case notAuthenticated
    case invalidState
    case profileCreationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidState:
            return "Invalid authentication state"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}
