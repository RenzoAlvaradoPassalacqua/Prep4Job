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
    let action: () -> Void

    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Text(title).font(.headline.weight(.semibold))
                if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Prep4JobTheme.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
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
    }
}
