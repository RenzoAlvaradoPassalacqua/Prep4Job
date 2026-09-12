import Foundation
import StoreKit

actor StoreKitSubscriptionService: SubscriptionService {
    private var cachedProducts: [Product] = []

    func products() async throws -> [SubscriptionProduct] {
        do {
            cachedProducts = try await Product.products(for: SubscriptionProductID.all)
            return cachedProducts.map(Self.mapProduct)
        } catch {
            throw SubscriptionError.storeUnavailable
        }
    }

    func purchase(productID: String) async throws -> SubscriptionEntitlement {
        let product = try await product(for: productID)
        let result = try await product.purchase()

        switch result {
        case let .success(verificationResult):
            let transaction = try verifiedTransaction(verificationResult)
            await transaction.finish()
            return Self.entitlement(for: transaction)
        case .userCancelled:
            throw SubscriptionError.purchaseCancelled
        case .pending:
            throw SubscriptionError.purchasePending
        @unknown default:
            throw SubscriptionError.storeUnavailable
        }
    }

    func restorePurchases() async throws -> SubscriptionEntitlement {
        do {
            try await AppStore.sync()
            return await currentEntitlement()
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.storeUnavailable
        }
    }

    func currentEntitlement() async -> SubscriptionEntitlement {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result,
                  SubscriptionProductID.all.contains(transaction.productID)
            else { continue }
            return Self.entitlement(for: transaction)
        }
        return .free
    }

    private func product(for productID: String) async throws -> Product {
        if let cachedProduct = cachedProducts.first(where: { $0.id == productID }) {
            return cachedProduct
        }
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw SubscriptionError.productNotFound }
        cachedProducts.append(product)
        return product
    }

    private func verifiedTransaction(
        _ result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case let .verified(transaction):
            transaction
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        }
    }

    private static func mapProduct(_ product: Product) -> SubscriptionProduct {
        SubscriptionProduct(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            periodDescription: periodDescription(for: product.subscription?.subscriptionPeriod)
        )
    }

    private static func periodDescription(for period: Product.SubscriptionPeriod?) -> String {
        guard let period else { return "" }
        switch period.unit {
        case .day:
            return L10n.Subscription.dailyPeriod
        case .week:
            return L10n.Subscription.weeklyPeriod
        case .month:
            return L10n.Subscription.monthlyPeriod
        case .year:
            return L10n.Subscription.yearlyPeriod
        @unknown default:
            return ""
        }
    }

    private static func entitlement(for transaction: Transaction) -> SubscriptionEntitlement {
        SubscriptionEntitlement(
            tier: .premium,
            productID: transaction.productID,
            expirationDate: transaction.expirationDate
        )
    }
}

actor DemoSubscriptionService: SubscriptionService {
    static let shared = DemoSubscriptionService()
    private var isPremium = false

    func products() async throws -> [SubscriptionProduct] {
        [
            SubscriptionProduct(
                id: SubscriptionProductID.monthly,
                displayName: L10n.Subscription.monthly,
                displayPrice: "$4.99",
                periodDescription: L10n.Subscription.monthlyPeriod
            ),
            SubscriptionProduct(
                id: SubscriptionProductID.yearly,
                displayName: L10n.Subscription.yearly,
                displayPrice: "$39.99",
                periodDescription: L10n.Subscription.yearlyPeriod
            )
        ]
    }

    func purchase(productID: String) async throws -> SubscriptionEntitlement {
        guard SubscriptionProductID.all.contains(productID) else {
            throw SubscriptionError.productNotFound
        }
        isPremium = true
        return SubscriptionEntitlement(tier: .premium, productID: productID, expirationDate: nil)
    }

    func restorePurchases() async throws -> SubscriptionEntitlement {
        isPremium ? SubscriptionEntitlement(
            tier: .premium,
            productID: SubscriptionProductID.monthly,
            expirationDate: nil
        ) : .free
    }

    func currentEntitlement() async -> SubscriptionEntitlement {
        isPremium
            ? SubscriptionEntitlement(tier: .premium, productID: SubscriptionProductID.monthly, expirationDate: nil)
            : .free
    }
}

enum SubscriptionServiceFactory {
    static func makeDefault() -> any SubscriptionService {
#if DEBUG
            return DemoSubscriptionService.shared
        #else
            return StoreKitSubscriptionService()
        #endif
    }
}
