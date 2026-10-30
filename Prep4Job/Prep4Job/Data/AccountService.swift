import Foundation
import Supabase

/// Servicio responsable de operaciones de cuenta del usuario.
/// Requiere una Edge Function segura del lado servidor que elimine datos del usuario
/// y desactive/borre al usuario de Auth. Véase: `delete_user_account`.
final class AccountService: @unchecked Sendable {
    private let client: SupabaseClient

    enum AccountServiceError: Error {
        case notAuthenticated
        case configurationMissing
    }

    init(client: SupabaseClient? = nil) {
        if let provided = client {
            self.client = provided
        } else if let made = SupabaseClientFactory.make() {
            self.client = made
        } else {
            fatalError("AccountService requires a configured SupabaseClient. Ensure SupabaseClientFactory.make() returns a client.")
        }
    }

    /// Elimina la cuenta del usuario actual invocando una Edge Function y cierra la sesión local.
    /// IMPORTANTE: La Edge Function `delete_user_account` debe:
    /// - Eliminar/anonimizar datos del usuario en todas las tablas relacionadas.
    /// - Desactivar o eliminar el usuario en el proveedor de Auth (operación con privilegios admin).
    /// - Validar que la llamada esté autenticada y autorizada para el usuario en cuestión.
    func deleteAccount() async throws -> Void {
        // Obtener la sesión actual de forma segura evitando combinar accesos async/throwing en un guard
        // Primero intentamos `currentSession` (sin async/throws). Si no hay sesión, pedimos `session` (async/throws).
        let session: Session?
        if let current = client.auth.currentSession {
            session = current
        } else {
            session = try? await client.auth.session
        }

        guard let userId = session?.user.id as UUID? else {
            throw AccountServiceError.notAuthenticated
        }
        // La función puede usar el userId del JWT; se incluye en el access token.
        _ = userId

        // Invocar Edge Function protegida. Payload vacío; el backend extrae el userId del token.
        struct EmptyPayload: Encodable {}
        _ = try await client.functions.invoke(
            "delete_user_account",
            options: FunctionInvokeOptions(
                body: EmptyPayload()
            )
        ) as Void

        // Tras eliminación servidor, cerrar sesión local.
        try await client.auth.signOut()
    }
}
