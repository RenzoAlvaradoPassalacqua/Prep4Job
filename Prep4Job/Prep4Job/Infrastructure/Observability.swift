import Foundation

nonisolated enum Observability {
    nonisolated(unsafe) private static var isStarted = false

    static func start() {
        #if DEBUG
        return
        #else
        guard !isStarted else { return }
        isStarted = true
        // Sentry removed: previously read DSN and started SentrySDK. Now a no-op.
        // If you had environment-based configuration, keep it here for future providers.
        _ = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"]
        #endif
    }

    static func capture(_ error: Error, context: [String: String] = [:]) {
        // Sentry removed: previously captured errors via SentrySDK. Now a no-op.
        guard isStarted else { return }
        _ = context // Preserve parameter to avoid unused warnings.
    }
}
