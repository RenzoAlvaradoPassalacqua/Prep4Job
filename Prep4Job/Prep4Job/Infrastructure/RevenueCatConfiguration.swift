import Foundation
import RevenueCat

nonisolated enum RevenueCatConfiguration {
    static let entitlementID = "prep4job_pro"
    /// RevenueCat public SDK keys are safe to ship in the client. Keep secret keys server-side.
    private static let defaultPublicAPIKey = "test_KZYDqiSpPZwtwEpnEiBZuZIJAdm"

    static var isConfigured: Bool {
        Purchases.isConfigured
    }

    @MainActor
    static func configure() {
        guard !Purchases.isConfigured, let apiKey else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        Purchases.configure(withAPIKey: apiKey)
    }

    private static var apiKey: String? {
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String
        let environmentValue = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]
        let candidate = infoValue ?? environmentValue ?? defaultPublicAPIKey

        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$("), !trimmed.hasPrefix("YOUR_") else { return nil }
        return trimmed
    }
}
