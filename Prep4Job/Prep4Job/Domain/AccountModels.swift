import Foundation

nonisolated struct UserAccount: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let email: String
    let displayName: String
    let createdAt: Date
}

nonisolated enum AuthState: Equatable, Sendable {
    case loading
    case signedOut
    case signedIn(UserAccount)
}

nonisolated enum AuthError: LocalizedError, Equatable, Sendable {
    case invalidCredentials
    case accountAlreadyExists
    case networkUnavailable
    case backendNotConfigured
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            L10n.Account.invalidCredentials
        case .accountAlreadyExists:
            L10n.Account.accountAlreadyExists
        case .networkUnavailable:
            L10n.Account.networkUnavailable
        case .backendNotConfigured:
            L10n.Account.backendNotConfigured
        case .invalidResponse:
            L10n.Account.invalidResponse
        }
    }
}

nonisolated protocol AuthService: Sendable {
    func restoreSession() async -> UserAccount?
    func signIn(email: String, password: String) async throws -> UserAccount
    func signUp(email: String, password: String, displayName: String) async throws -> UserAccount
    func signOut() async
    func deleteAccount() async throws
}
