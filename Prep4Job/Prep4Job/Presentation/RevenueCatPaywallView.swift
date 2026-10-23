import RevenueCat
import RevenueCatUI
import SwiftUI

/// Loads the current RevenueCat offering and renders the remotely managed paywall.
/// Product ordering, prices and copy remain controlled from the RevenueCat dashboard.
struct RevenueCatPaywallView: View {
    @State private var offering: Offering?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering, displayCloseButton: true)
            } else if let errorMessage {
                ContentUnavailableView(
                    L10n.Subscription.paywall,
                    systemImage: "cart.badge.exclamationmark",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView(L10n.Common.loading)
            }
        }
        .task { await loadOffering() }
    }

    @MainActor
    private func loadOffering() async {
        guard RevenueCatConfiguration.isConfigured else {
            errorMessage = L10n.Subscription.revenueCatUnavailable
            return
        }

        do {
            offering = try await Purchases.shared.offerings().current
            if offering == nil {
                errorMessage = L10n.Subscription.storeUnavailable
            }
        } catch {
            errorMessage = L10n.Subscription.storeUnavailable
        }
    }
}
