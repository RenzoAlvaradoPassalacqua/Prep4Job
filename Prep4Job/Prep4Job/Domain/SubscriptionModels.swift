import Foundation

nonisolated enum SubscriptionTier: String, Codable, Sendable {
    case free
    case premium
}

nonisolated struct SubscriptionProduct: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let periodDescription: String
}

nonisolated struct SubscriptionEntitlement: Codable, Equatable, Sendable {
    let tier: SubscriptionTier
    let productID: String?
    let expirationDate: Date?

    var isActive: Bool {
        tier == .premium && (expirationDate == nil || expirationDate ?? .distantPast > Date())
    }

    static let free = SubscriptionEntitlement(tier: .free, productID: nil, expirationDate: nil)
}

nonisolated enum SubscriptionError: LocalizedError, Equatable, Sendable {
    case productNotFound
    case purchasePending
    case purchaseCancelled
    case unverifiedTransaction
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            L10n.Subscription.productNotFound
        case .purchasePending:
            L10n.Subscription.purchasePending
        case .purchaseCancelled:
            L10n.Subscription.purchaseCancelled
        case .unverifiedTransaction:
            L10n.Subscription.unverifiedTransaction
        case .storeUnavailable:
            L10n.Subscription.storeUnavailable
        }
    }
}

nonisolated protocol SubscriptionService: Sendable {
    func products() async throws -> [SubscriptionProduct]
    func purchase(productID: String) async throws -> SubscriptionEntitlement
    func restorePurchases() async throws -> SubscriptionEntitlement
    func currentEntitlement() async -> SubscriptionEntitlement
}

nonisolated enum SubscriptionProductID {
    static let monthly = "prep4job.premium.monthly"
    static let yearly = "prep4job.premium.yearly"
    static let all = [monthly, yearly]
}
