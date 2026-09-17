import SwiftUI
import RevenueCatUI

struct AccountView: View {
    @StateObject private var session: SessionStore
    @StateObject private var subscription: SubscriptionStore

    init(
        session: SessionStore? = nil,
        subscription: SubscriptionStore? = nil
    ) {
        _session = StateObject(wrappedValue: session ?? SessionStore())
        _subscription = StateObject(wrappedValue: subscription ?? SubscriptionStore())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                switch session.state {
                case .loading:
                    LoadingStateView()
                case .signedOut:
                    AuthForm(session: session)
                case let .signedIn(account):
                    SignedInAccountView(
                        account: account,
                        session: session,
                        subscription: subscription
                    )
                }
            }
            .padding(20)
        }
        .background(Prep4JobTheme.canvas)
        .navigationTitle(L10n.Account.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.restore()
            if let account = session.account {
                await subscription.identify(userID: account.id)
            }
            await subscription.load()
        }
        .onChange(of: session.account?.id) { _, accountID in
            Task {
                if let accountID {
                    await subscription.identify(userID: accountID)
                } else {
                    await subscription.resetIdentity()
                }
                await subscription.load()
            }
        }
    }
}

private struct AuthForm: View {
    @ObservedObject var session: SessionStore
    @State private var isCreatingAccount = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isCreatingAccount ? L10n.Account.createTitle : L10n.Account.signInTitle)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Prep4JobTheme.ink)
            Text(L10n.Subscription.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if isCreatingAccount {
                TextField(L10n.Account.displayName, text: $displayName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.Account.displayName)
            }
            TextField(L10n.Account.email, text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.Account.email)
            SecureField(L10n.Account.password, text: $password)
                .textContentType(isCreatingAccount ? .newPassword : .password)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.Account.password)

            if let error = session.error {
                InlineStatusMessage(message: error.localizedDescription)
            }

            PrimaryButton(
                title: isCreatingAccount ? L10n.Account.signUp : L10n.Account.signIn,
                systemImage: isCreatingAccount ? "person.badge.plus" : "arrow.right",
                isLoading: session.isLoading
            ) {
                Task {
                    if isCreatingAccount {
                        await session.signUp(email: email, password: password, displayName: displayName)
                    } else {
                        await session.signIn(email: email, password: password)
                    }
                }
            }

            Button(isCreatingAccount ? L10n.Account.switchToSignIn : L10n.Account.switchToSignUp) {
                isCreatingAccount.toggle()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Prep4JobTheme.indigo)
            .disabled(session.isLoading)

            Label(L10n.Account.developmentMode, systemImage: "hammer.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SignedInAccountView: View {
    let account: UserAccount
    @ObservedObject var session: SessionStore
    @ObservedObject var subscription: SubscriptionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Card {
                VStack(alignment: .leading, spacing: 5) {
                    Label(account.displayName, systemImage: "person.crop.circle.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Prep4JobTheme.ink)
                    Text(account.email).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            PremiumCard(subscription: subscription)

            Button(L10n.Account.signOut, role: .destructive) {
                Task { await session.signOut() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .accessibilityHint(Text(L10n.Account.signOut))

            NavigationLink {
                LegalView(session: session)
            } label: {
                Label(L10n.Account.legal, systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Prep4JobTheme.indigo)
            }
        }
    }
}

private struct LegalView: View {
    @ObservedObject var session: SessionStore
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.Account.privacy).font(.title2.weight(.bold))
                Text(L10n.Account.legalBody).foregroundStyle(.secondary)
                Divider()
                Text(L10n.Account.terms).font(.title2.weight(.bold))
                Text(L10n.Account.termsBody)
                    .foregroundStyle(.secondary)
                Divider()
                Button(L10n.Account.deleteAccount, role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .font(.subheadline.weight(.semibold))
                if let error = session.error {
                    InlineStatusMessage(message: error.localizedDescription)
                }
            }
            .padding(20)
        }
        .navigationTitle(L10n.Account.legal)
        .alert(L10n.Account.deleteAccount, isPresented: $showingDeleteConfirmation) {
            Button(L10n.Account.cancel, role: .cancel) {}
            Button(L10n.Account.confirmDelete, role: .destructive) {
                Task { await session.deleteAccount() }
            }
        } message: {
            Text(L10n.Account.deleteAccountMessage)
        }
    }
}

private struct PremiumCard: View {
    @ObservedObject var subscription: SubscriptionStore
    @State private var isPaywallPresented = false
    @State private var isCustomerCenterPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                subscription.isPremium ? L10n.Subscription.premiumActive : L10n.Subscription.title,
                systemImage: subscription.isPremium ? "checkmark.seal.fill" : "sparkles"
            )
            .font(.headline.weight(.bold))
            .foregroundStyle(Prep4JobTheme.indigo)
            Text(L10n.Subscription.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if subscription.products.isEmpty {
                Text(L10n.Subscription.storeUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(subscription.products) { product in
                    Button {
                        Task { await subscription.purchase(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.displayName).font(.subheadline.weight(.semibold))
                                Text(product.periodDescription).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice).font(.headline.weight(.bold))
                        }
                        .foregroundStyle(Prep4JobTheme.ink)
                        .padding(12)
                        .background(Prep4JobTheme.indigo.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(subscription.isLoading || subscription.isPremium)
                    .accessibilityLabel("(product.displayName), (product.displayPrice)")
                    .accessibilityHint(Text(product.periodDescription))
                }
            }

            SecondaryButton(
                title: L10n.Subscription.restore,
                systemImage: "arrow.clockwise",
                isLoading: subscription.isLoading
            ) {
                Task { await subscription.restorePurchases() }
            }

            if RevenueCatConfiguration.isConfigured {
                Button {
                    isPaywallPresented = true
                } label: {
                    Label(L10n.Subscription.paywall, systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Prep4JobTheme.indigo)
                .disabled(subscription.isLoading || subscription.isPremium)

                Button {
                    isCustomerCenterPresented = true
                } label: {
                    Label(L10n.Subscription.customerCenter, systemImage: "person.crop.circle.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Prep4JobTheme.indigo)
            }

            if let error = subscription.error {
                InlineStatusMessage(message: error.localizedDescription)
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sheet(isPresented: $isPaywallPresented) {
            RevenueCatPaywallView()
                .onDisappear { Task { await subscription.load() } }
        }
        .sheet(isPresented: $isCustomerCenterPresented) {
            CustomerCenterView()
                .onCustomerCenterRestoreCompleted { _ in
                    Task { await subscription.load() }
                }
                .onDisappear { Task { await subscription.load() } }
        }
    }
}
