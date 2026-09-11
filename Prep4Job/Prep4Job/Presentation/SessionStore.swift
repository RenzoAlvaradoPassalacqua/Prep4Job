import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var state: AuthState = .loading
    @Published private(set) var error: AuthError?

    private let service: any AuthService

    init(service: (any AuthService)? = nil) {
        self.service = service ?? AuthServiceFactory.makeDefault()
    }

    var account: UserAccount? {
        guard case let .signedIn(account) = state else { return nil }
        return account
    }

    func restore() async {
        state = .loading
        let account = await service.restoreSession()
        state = account.map(AuthState.signedIn) ?? .signedOut
    }

    func signIn(email: String, password: String) async {
        await authenticate {
            try await service.signIn(email: email, password: password)
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        await authenticate {
            try await service.signUp(email: email, password: password, displayName: displayName)
        }
    }

    func signOut() async {
        await service.signOut()
        state = .signedOut
    }

    func deleteAccount() async {
        error = nil
        do {
            try await service.deleteAccount()
            state = .signedOut
        } catch let authError as AuthError {
            self.error = authError
        } catch {
            self.error = .networkUnavailable
        }
    }

    private func authenticate(_ operation: () async throws -> UserAccount) async {
        error = nil
        do {
            state = try .signedIn(await operation())
        } catch let authError as AuthError {
            self.error = authError
        } catch {
            self.error = .networkUnavailable
        }
    }
}
