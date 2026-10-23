import Foundation
import RevenueCat

actor RevenueCatSubscriptionService: SubscriptionService {
    private let purchases: Purchases

    init(purchases: Purchases = .shared) {
        self.purchases = purchases
    }

    func products() async throws -> [SubscriptionProduct] {
        guard RevenueCatConfiguration.isConfigured else {
            throw SubscriptionError.storeUnavailable
        }

        do {
            guard let offering = try await purchases.offerings().current else {
                throw SubscriptionError.productNotFound
            }
            let products = offering.availablePackages.map(Self.mapProduct)
            return SubscriptionProductID.all.compactMap { productID in
                products.first(where: { $0.id == productID })
            }
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw Self.mapError(error)
        }
    }

    func purchase(productID: String) async throws -> SubscriptionEntitlement {
        guard RevenueCatConfiguration.isConfigured else {
            throw SubscriptionError.storeUnavailable
        }

        do {
            guard let package = try await package(for: productID) else {
                throw SubscriptionError.productNotFound
            }
            let result = try await purchases.purchase(package: package)
            guard !result.userCancelled else {
                throw SubscriptionError.purchaseCancelled
            }
            return Self.entitlement(from: result.customerInfo)
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw Self.mapError(error)
        }
    }

    func restorePurchases() async throws -> SubscriptionEntitlement {
        guard RevenueCatConfiguration.isConfigured else {
            throw SubscriptionError.storeUnavailable
        }

        do {
            let customerInfo = try await purchases.restorePurchases()
            return Self.entitlement(from: customerInfo)
        } catch {
            throw Self.mapError(error)
        }
    }

    func currentEntitlement() async -> SubscriptionEntitlement {
        guard RevenueCatConfiguration.isConfigured else { return .free }

        do {
            let customerInfo = try await purchases.customerInfo()
            return Self.entitlement(from: customerInfo)
        } catch {
            return .free
        }
    }

    func identify(userID: String) async {
        guard RevenueCatConfiguration.isConfigured, !userID.isEmpty else { return }
        _ = try? await purchases.logIn(userID)
    }

    func resetIdentity() async {
        guard RevenueCatConfiguration.isConfigured, !purchases.isAnonymous else { return }
        _ = try? await purchases.logOut()
    }

    private func package(for productID: String) async throws -> RevenueCat.Package? {
        guard let offering = try await purchases.offerings().current else { return nil }
        return offering.availablePackages.first {
            $0.storeProduct.productIdentifier == productID
        }
    }

    private static func mapProduct(_ package: RevenueCat.Package) -> SubscriptionProduct {
        SubscriptionProduct(
            id: package.storeProduct.productIdentifier,
            displayName: package.storeProduct.localizedTitle,
            displayPrice: package.storeProduct.localizedPriceString,
            periodDescription: periodDescription(for: package.storeProduct.subscriptionPeriod)
        )
    }

    private static func periodDescription(for period: SubscriptionPeriod?) -> String {
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

    private static func entitlement(from customerInfo: CustomerInfo) -> SubscriptionEntitlement {
        guard let entitlement = customerInfo.entitlements[RevenueCatConfiguration.entitlementID],
              entitlement.isActive else {
            return .free
        }

        return SubscriptionEntitlement(
            tier: .premium,
            productID: entitlement.productIdentifier,
            expirationDate: entitlement.expirationDate
        )
    }

    private static func mapError(_ error: Error) -> SubscriptionError {
        guard let errorCode = error as? RevenueCat.ErrorCode else {
            return .storeUnavailable
        }

        switch errorCode {
        case .purchaseCancelledError:
            return .purchaseCancelled
        case .paymentPendingError:
            return .purchasePending
        case .productNotAvailableForPurchaseError:
            return .productNotFound
        default:
            return .storeUnavailable
        }
    }
}
