import SwiftUI

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
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
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
            await subscription.load()
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
            }
            TextField(L10n.Account.email, text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField(L10n.Account.password, text: $password)
                .textContentType(isCreatingAccount ? .newPassword : .password)
                .textFieldStyle(.roundedBorder)

            if let error = session.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            PrimaryButton(
                title: isCreatingAccount ? L10n.Account.signUp : L10n.Account.signIn,
                systemImage: isCreatingAccount ? "person.badge.plus" : "arrow.right"
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

            Button(L10n.Account.signOut) {
                Task { await session.signOut() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)

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
                    Text(error.localizedDescription).font(.caption).foregroundStyle(.red)
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
                }
            }

            Button(L10n.Subscription.restore) {
                Task { await subscription.restorePurchases() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Prep4JobTheme.indigo)

            if let error = subscription.error {
                Text(error.localizedDescription).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
