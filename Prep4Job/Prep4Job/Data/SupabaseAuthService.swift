import Foundation
import Supabase

// Kept as a decoding compatibility model for migration tests and persisted fixtures.
nonisolated struct SupabaseSessionResponse: Decodable, Sendable {
    let accessToken: String?
    let user: SupabaseUser?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case session
        case user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try container.decodeIfPresent(SupabaseSession.self, forKey: .session)
        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken) ?? nested?.accessToken
        user = try container.decodeIfPresent(SupabaseUser.self, forKey: .user) ?? nested?.user
    }
}

nonisolated private struct SupabaseSession: Decodable, Sendable {
    let accessToken: String?
    let user: SupabaseUser?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

nonisolated struct SupabaseUser: Decodable, Sendable {
    let id: UUID?
    let email: String?
    let createdAt: Date?
    let userMetadata: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case userMetadata = "user_metadata"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        userMetadata = try container.decodeIfPresent([String: String].self, forKey: .userMetadata)
        if let rawDate = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let standard = ISO8601DateFormatter()
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = standard.date(from: rawDate) ?? fractional.date(from: rawDate)
        } else {
            createdAt = nil
        }
    }

    nonisolated var account: UserAccount? {
        guard let id, let email else { return nil }
        let name = userMetadata?["display_name"] ?? email.split(separator: "@").first.map(String.init) ?? email
        return UserAccount(id: id, email: email, displayName: name, createdAt: createdAt ?? Date())
    }
}

nonisolated struct SupabaseConfiguration: Sendable {
    let url: URL
    let publishableKey: String
}

nonisolated enum SupabaseConfigurationProvider {
    static func make() -> SupabaseConfiguration? {
        let environment = ProcessInfo.processInfo.environment
        let urlString = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)
            ?? environment["SUPABASE_URL"]
            ?? "https://acwfqycsiauktidsvgci.supabase.co"
        let key = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String)
            ?? environment["SUPABASE_PUBLISHABLE_KEY"]
            ?? "sb_publishable_hf8it8jHmBjK7kAqYZUQSw_eoI74gjO"
        guard let url = URL(string: urlString), !key.isEmpty else { return nil }
        return SupabaseConfiguration(url: url, publishableKey: key)
    }
}

nonisolated enum SupabaseClientFactory {
    static func make() -> SupabaseClient? {
        guard let configuration = SupabaseConfigurationProvider.make() else { return nil }
        return SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}

actor SupabaseAuthService: AuthService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func accessToken() async -> String? {
        client.auth.currentSession?.accessToken
    }

    func restoreSession() async -> UserAccount? {
        do {
            let session = try await client.auth.session
            await AuthSessionCoordinator.shared.setToken(session.accessToken)
            return makeAccount(from: session.user)
        } catch {
            await AuthSessionCoordinator.shared.setToken(nil)
            return nil
        }
    }

    func signIn(email: String, password: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            await AuthSessionCoordinator.shared.setToken(session.accessToken)
            NotificationCenter.default.post(name: .prep4jobAuthStateDidChange, object: nil)
            return makeAccount(from: session.user)
        } catch {
            throw map(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(name)]
            )
            guard let session = response.session else {
                await AuthSessionCoordinator.shared.setToken(nil)
                throw AuthError.emailConfirmationRequired
            }
            await AuthSessionCoordinator.shared.setToken(session.accessToken)
            NotificationCenter.default.post(name: .prep4jobAuthStateDidChange, object: nil)
            return makeAccount(from: response.user)
        } catch let error as AuthError {
            throw error
        } catch {
            throw map(error)
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        await AuthSessionCoordinator.shared.setToken(nil)
        NotificationCenter.default.post(name: .prep4jobAuthStateDidChange, object: nil)
    }

    func deleteAccount() async throws {
        guard client.auth.currentSession != nil else { throw AuthError.invalidCredentials }
        do {
            try await client.functions.invoke("delete-account")
            try? await client.auth.signOut()
            await AuthSessionCoordinator.shared.setToken(nil)
        } catch {
            throw map(error)
        }
    }

    private func makeAccount(from user: Supabase.User) -> UserAccount {
        let displayName: String
        if case let .string(name) = user.userMetadata["display_name"], !name.isEmpty {
            displayName = name
        } else {
            displayName = user.email?.split(separator: "@").first.map(String.init) ?? "Prep4Job"
        }
        return UserAccount(id: user.id, email: user.email ?? "", displayName: displayName, createdAt: user.createdAt)
    }

    private func map(_ error: Error) -> AuthError {
        let message = error.localizedDescription.lowercased()
        if message.contains("already registered") || message.contains("email_exists") { return .accountAlreadyExists }
        if message.contains("weak_password")
            || (message.contains("password") && message.contains("character")) {
            return .invalidPassword
        }
        if message.contains("invalid email") || message.contains("email is invalid") { return .invalidEmail }
        if message.contains("invalid login") || message.contains("invalid credentials") { return .invalidCredentials }
        if message.contains("network") || message.contains("offline") { return .networkUnavailable }
        return .backendMessage(error.localizedDescription)
    }
}

enum AuthServiceFactory {
    static func makeDefault() -> any AuthService {
        if let client = SupabaseClientFactory.make() { return SupabaseAuthService(client: client) }
        return LocalAuthService()
    }
}
