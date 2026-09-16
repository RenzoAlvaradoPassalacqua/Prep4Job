import SwiftUI

enum Prep4JobTheme {
    static let indigo = Color(red: 0.18, green: 0.22, blue: 0.72)
    static let violet = Color(red: 0.42, green: 0.34, blue: 0.87)
    static let mint = Color(red: 0.18, green: 0.73, blue: 0.58)
    static let amber = Color(red: 0.97, green: 0.63, blue: 0.18)
    static let ink = Color(red: 0.08, green: 0.10, blue: 0.20)
    static let canvas = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let card = Color.white

    static let softGradient = LinearGradient(
        colors: [Color(red: 0.91, green: 0.92, blue: 1), Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background(Prep4JobTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel(L10n.Common.loading)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.bold))
                }
                Text(title).font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(.white)
            .background(Prep4JobTheme.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? Text(L10n.Common.loading) : Text(""))
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if isLoading {
                    ProgressView()
                        .tint(Prep4JobTheme.indigo)
                        .accessibilityLabel(L10n.Common.loading)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.bold))
                }
                Text(title).font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(Prep4JobTheme.indigo)
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Prep4JobTheme.indigo, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? Text(L10n.Common.loading) : Text(""))
        .accessibilityAddTraits(.isButton)
    }
}

struct LoadingStateView: View {
    var message: String = L10n.Common.loading

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Prep4JobTheme.indigo)
                .controlSize(.regular)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "tray"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Prep4JobTheme.indigo)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Prep4JobTheme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                SecondaryButton(title: actionTitle, systemImage: "arrow.clockwise", action: action)
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 40)
    }
}

struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Prep4JobTheme.amber)
                .accessibilityHidden(true)
            Text(L10n.Common.errorTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(Prep4JobTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                SecondaryButton(title: L10n.Common.retry, systemImage: "arrow.clockwise", action: retry)
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
    }
}

struct InlineStatusMessage: View {
    enum Style {
        case error
        case info
        case success

        var color: Color {
            switch self {
            case .error: .red
            case .info: Prep4JobTheme.indigo
            case .success: Prep4JobTheme.mint
            }
        }

        var icon: String {
            switch self {
            case .error: "exclamationmark.circle.fill"
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            }
        }
    }

    let message: String
    var style: Style = .error

    var body: some View {
        Label(message, systemImage: style.icon)
            .font(.caption)
            .foregroundStyle(style.color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(message))
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct ProgressRing: View {
    let value: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.13), lineWidth: 9)
            Circle().trim(from: 0, to: value).stroke(
                Prep4JobTheme.mint,
                style: StrokeStyle(lineWidth: 9, lineCap: .round)
            ).rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(L10n.Common.percent(Int(value * 100))).font(.title2.weight(.bold))
                    .foregroundStyle(Prep4JobTheme.ink)
                Text(L10n.Common.ready).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(L10n.Common.percent(Int(value * 100))))
        .accessibilityValue(Text(L10n.Common.ready))
    }
}
