import Combine
import Foundation

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var entitlement = SubscriptionEntitlement.free
    @Published private(set) var isLoading = false
    @Published private(set) var error: SubscriptionError?

    private let service: any SubscriptionService

    init(service: (any SubscriptionService)? = nil) {
        self.service = service ?? SubscriptionServiceFactory.makeDefault()
    }

    var isPremium: Bool {
        entitlement.isActive
    }

    func identify(userID: UUID) async {
        await service.identify(userID: userID.uuidString)
    }

    func resetIdentity() async {
        await service.resetIdentity()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchedProducts = service.products()
            async let currentEntitlement = service.currentEntitlement()
            products = try await fetchedProducts
            entitlement = await currentEntitlement
        } catch let subscriptionError as SubscriptionError {
            self.error = subscriptionError
        } catch {
            self.error = .storeUnavailable
        }
    }

    func purchase(_ product: SubscriptionProduct) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            entitlement = try await service.purchase(productID: product.id)
            NotificationCenter.default.post(name: .prep4jobEntitlementDidChange, object: nil)
        } catch let subscriptionError as SubscriptionError {
            self.error = subscriptionError
        } catch {
            self.error = .storeUnavailable
        }
    }

    func restorePurchases() async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            entitlement = try await service.restorePurchases()
            NotificationCenter.default.post(name: .prep4jobEntitlementDidChange, object: nil)
        } catch let subscriptionError as SubscriptionError {
            self.error = subscriptionError
        } catch {
            self.error = .storeUnavailable
        }
    }
}
