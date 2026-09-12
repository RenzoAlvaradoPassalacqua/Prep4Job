import Foundation

nonisolated struct SupabaseConfiguration: Sendable {
    let url: URL
    let publishableKey: String
}

actor SupabaseAuthService: AuthService {
    private let configuration: SupabaseConfiguration
    private let sessionURL: URL
    private let userURL: URL
    private let urlSession: URLSession
    private var sessionAccessToken: String?

    func accessToken() async -> String? { sessionAccessToken }

    init(configuration: SupabaseConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        sessionURL = configuration.url.appendingPathComponent("auth/v1/token")
        userURL = configuration.url.appendingPathComponent("auth/v1/user")
        self.urlSession = urlSession
    }

    func restoreSession() async -> UserAccount? {
        guard let accessToken = sessionAccessToken else { return nil }
        do {
            return try await requestUser(accessToken: accessToken)
        } catch {
            self.sessionAccessToken = nil
            return nil
        }
    }

    func signIn(email: String, password: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        return try await authenticate(email: email, password: password, endpoint: sessionURL)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        var request = try makeRequest(
            url: configuration.url.appendingPathComponent("auth/v1/signup"),
            method: "POST"
        )
        request.httpBody = try JSONEncoder().encode(SignUpRequest(
            email: email,
            password: password,
            data: ["display_name": normalizedName]
        ))

        do {
            let (data, response) = try await urlSession.data(for: request)
            try validate(response: response, data: data, isSignUp: true)
            let payload = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)
            guard let user = payload.user, let account = user.account else { throw AuthError.invalidResponse }
            guard let accessToken = payload.accessToken else {
                sessionAccessToken = nil
                await AuthSessionCoordinator.shared.setToken(nil)
                throw AuthError.emailConfirmationRequired
            }
            sessionAccessToken = accessToken
            await AuthSessionCoordinator.shared.setToken(accessToken)
            return account
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkUnavailable
        }
    }

    func signOut() async {
        guard let accessToken = sessionAccessToken else { return }
        let request = try? makeRequest(
            url: configuration.url.appendingPathComponent("auth/v1/logout"),
            method: "POST",
            accessToken: accessToken
        )
        if let request {
            _ = try? await urlSession.data(for: request)
        }
        self.sessionAccessToken = nil
        await AuthSessionCoordinator.shared.setToken(nil)
    }

    func deleteAccount() async throws {
        guard let accessToken = sessionAccessToken else { throw AuthError.invalidCredentials }
        let request = try makeRequest(
            url: configuration.url.appendingPathComponent("functions/v1/delete-account"),
            method: "POST",
            accessToken: accessToken
        )
        let (_, response) = try await urlSession.data(for: request)
        try validate(response: response)
        self.sessionAccessToken = nil
    }

    private func authenticate(email: String, password: String, endpoint: URL) async throws -> UserAccount {
        var request = try makeRequest(url: endpoint, method: "POST")
        request.url = endpoint.appending(queryItems: [URLQueryItem(name: "grant_type", value: "password")])
        request.httpBody = try JSONEncoder().encode(LoginRequest(email: email, password: password))

        do {
            let (data, response) = try await urlSession.data(for: request)
            try validate(response: response, data: data, isSignUp: false)
            let payload = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)
            guard let user = payload.user, let account = user.account else { throw AuthError.invalidResponse }
            guard let accessToken = payload.accessToken else { throw AuthError.invalidResponse }
            sessionAccessToken = accessToken
            await AuthSessionCoordinator.shared.setToken(accessToken)
            return account
        } catch let error as AuthError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw AuthError.networkUnavailable
        } catch {
            throw AuthError.invalidCredentials
        }
    }

    private func requestUser(accessToken: String) async throws -> UserAccount {
        let request = try makeRequest(url: userURL, method: "GET", accessToken: accessToken)
        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response)
        let user = try JSONDecoder().decode(SupabaseUser.self, from: data)
        guard let account = user.account else { throw AuthError.invalidResponse }
        return account
    }

    private func makeRequest(url: URL, method: String, accessToken: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func validate(response: URLResponse, data: Data = Data(), isSignUp: Bool = false) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200 ..< 300 ~= httpResponse.statusCode
        else {
            if let body = String(data: data, encoding: .utf8)?.lowercased() {
                if isSignUp && (body.contains("already registered") || body.contains("already exists")
                    || body.contains("user_already_exists") || body.contains("email_exists")) {
                    throw AuthError.accountAlreadyExists
                }
                if body.contains("weak_password") || body.contains("password should be") {
                    throw AuthError.invalidPassword
                }
                if body.contains("invalid email") || body.contains("email is invalid") {
                    throw AuthError.invalidEmail
                }
                if let responseMessage = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data).message,
                   !responseMessage.isEmpty {
                    throw AuthError.backendMessage(responseMessage)
                }
            }
            throw AuthError.invalidCredentials
        }
    }
}

private struct SupabaseErrorResponse: Decodable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message = "msg"
    }
}

nonisolated struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}

nonisolated struct SignUpRequest: Encodable, Sendable {
    let email: String
    let password: String
    let data: [String: String]
}

nonisolated struct SupabaseSessionResponse: Decodable, Sendable {
    let accessToken: String?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case session
        case user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let session = try container.decodeIfPresent(SupabaseSession.self, forKey: .session)
        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken) ?? session?.accessToken
        user = try container.decodeIfPresent(SupabaseUser.self, forKey: .user) ?? session?.user
    }
}

private nonisolated struct SupabaseSession: Decodable, Sendable {
    let accessToken: String?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

nonisolated struct SupabaseUser: Decodable, Sendable {
    let id: UUID?
    let email: String?
    let createdAt: Date?
    let userMetadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case userMetadata = "user_metadata"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(UUID.self, forKey: .id)
        email = try? container.decodeIfPresent(String.self, forKey: .email)
        userMetadata = try? container.decodeIfPresent([String: String].self, forKey: .userMetadata)
        if let value = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: value)
                ?? ISO8601DateFormatter.withFractionalSeconds.date(from: value)
        } else {
            createdAt = nil
        }
    }

    nonisolated var account: UserAccount? {
        guard let id, let email else { return nil }
        let displayName = userMetadata?["display_name"] ?? email.split(separator: "@").first.map(String.init) ?? email
        return UserAccount(id: id, email: email, displayName: displayName, createdAt: createdAt ?? Date())
    }
}

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

enum AuthServiceFactory {
    static func makeDefault() -> any AuthService {
        let environment = ProcessInfo.processInfo.environment
        let urlString = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)
            ?? environment["SUPABASE_URL"]
            ?? "https://acwfqycsiauktidsvgci.supabase.co"
        let publishableKey = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String)
            ?? environment["SUPABASE_PUBLISHABLE_KEY"]
            ?? "sb_publishable_hf8it8jHmBjK7kAqYZUQSw_eoI74gjO"
        guard let url = URL(string: urlString), !publishableKey.isEmpty
        else {
            return LocalAuthService()
        }
        return SupabaseAuthService(configuration: SupabaseConfiguration(url: url, publishableKey: publishableKey))
    }
}
