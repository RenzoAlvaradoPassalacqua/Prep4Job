import Foundation

actor LocalAuthService: AuthService {
    func accessToken() async -> String? { nil }
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
    }

    func restoreSession() async -> UserAccount? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(UserAccount.self, from: data)
    }

    func signIn(email: String, password: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        guard let account = await restoreSession(), account.email.caseInsensitiveCompare(email) == .orderedSame else {
            throw AuthError.invalidCredentials
        }
        return account
    }

    func signUp(email: String, password: String, displayName: String) async throws -> UserAccount {
        guard let email = AuthInputValidator.email(email) else { throw AuthError.invalidEmail }
        guard AuthInputValidator.password(password) != nil else { throw AuthError.invalidPassword }
        if await restoreSession() != nil {
            throw AuthError.accountAlreadyExists
        }

        let account = UserAccount(
            id: UUID(),
            email: email,
            displayName: displayName.isEmpty ? email.split(separator: "@").first
                .map(String.init) ?? email : displayName,
            createdAt: Date()
        )
        try? save(account)
        return account
    }

    func signOut() async {
        try? FileManager.default.removeItem(at: fileURL)
        NotificationCenter.default.post(name: .prep4jobAuthStateDidChange, object: nil)
    }

    func deleteAccount() async throws {
        try FileManager.default.removeItem(at: fileURL)
    }

    private func save(_ account: UserAccount) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(account)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return directory.appendingPathComponent("prep4job-local-account.json")
    }
}
