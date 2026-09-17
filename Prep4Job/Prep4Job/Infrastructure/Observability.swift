import Foundation
import Sentry

nonisolated enum Observability {
    nonisolated(unsafe) private static var isStarted = false

    static func start() {
        #if DEBUG
        return
        #else
        guard !isStarted else { return }
        isStarted = true
        let environment = ProcessInfo.processInfo.environment
        let dsn = (Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String)
            ?? environment["SENTRY_DSN"]
        guard let dsn, !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment["APP_ENVIRONMENT"] ?? "development"
            options.tracesSampleRate = 0
            options.enableAutoPerformanceTracing = false
            options.enableTimeToFullDisplayTracing = false
            options.enableAutoSessionTracking = true
        }
        #endif
    }

    static func capture(_ error: Error, context: [String: String] = [:]) {
        guard isStarted else { return }
        SentrySDK.capture(error: error) { scope in
            context.forEach { scope.setTag(value: $0.value, key: $0.key) }
        }
    }
}
