import Foundation

nonisolated extension Notification.Name {
    static let prep4jobAuthStateDidChange = Notification.Name("Prep4Job.authStateDidChange")
    static let prep4jobEntitlementDidChange = Notification.Name("Prep4Job.entitlementDidChange")
}

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
    case invalidEmail
    case invalidPassword
    case invalidCredentials
    case backendMessage(String)
    case accountAlreadyExists
    case networkUnavailable
    case backendNotConfigured
    case emailConfirmationRequired
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            L10n.Account.invalidEmail
        case .invalidPassword:
            L10n.Account.invalidPassword
        case .invalidCredentials:
            L10n.Account.invalidCredentials
        case let .backendMessage(message):
            message
        case .accountAlreadyExists:
            L10n.Account.accountAlreadyExists
        case .networkUnavailable:
            L10n.Account.networkUnavailable
        case .backendNotConfigured:
            L10n.Account.backendNotConfigured
        case .emailConfirmationRequired:
            L10n.Account.emailConfirmationRequired
        case .invalidResponse:
            L10n.Account.invalidResponse
        }
    }
}

nonisolated enum AuthInputValidator {
    static func email(_ value: String) -> String? {
        let normalized = value
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: .controlCharacters)
            .lowercased()
        let components = normalized.split(separator: "@", omittingEmptySubsequences: false)
        guard normalized.count <= 254,
              components.count == 2,
              !components[0].isEmpty,
              components[1].contains("."),
              !components[1].hasPrefix("."),
              !components[1].hasSuffix(".") else { return nil }
        return normalized
    }

    static func password(_ value: String) -> String? {
        guard value.count >= 6 else { return nil }
        return value
    }
}

nonisolated protocol AuthService: Sendable {
    func accessToken() async -> String?
    func restoreSession() async -> UserAccount?
    func signIn(email: String, password: String) async throws -> UserAccount
    func signUp(email: String, password: String, displayName: String) async throws -> UserAccount
    func signOut() async
    func deleteAccount() async throws
}

actor AuthSessionCoordinator {
    static let shared = AuthSessionCoordinator()
    private var token: String?

    func setToken(_ token: String?) { self.token = token }
    func accessToken() -> String? { token }
}
