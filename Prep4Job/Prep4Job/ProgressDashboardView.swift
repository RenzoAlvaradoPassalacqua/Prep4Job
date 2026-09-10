import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel: ProgressViewModel
    private let values = [0.42, 0.66, 0.42, 0.55, 0.76, 1.0, 0.60]
    private let days = L10n.Progress.days

    init(store: PrepStore) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L10n.Progress.title).font(.largeTitle.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                    Text(L10n.Progress.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Card {
                        HStack(alignment: .bottom, spacing: 11) {
                            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                                VStack(spacing: 7) {
                                    Capsule()
                                        .fill(index == 5 ? Prep4JobTheme.indigo : Prep4JobTheme.indigo.opacity(0.25))
                                        .frame(
                                            width: 22,
                                            height: CGFloat(100 * value)
                                        )
                                    Text(days[index]).font(.caption2).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .bottom)
                            }
                        }
                        .frame(height: 135)
                    }
                    HStack(spacing: 10) {
                        StatCard(
                            value: viewModel.completedConceptCount,
                            label: L10n.Progress.concepts,
                            icon: "book.closed.fill",
                            color: Prep4JobTheme.indigo
                        )
                        StatCard(
                            value: viewModel.answeredQuestionCount,
                            label: L10n.Progress.answers,
                            icon: "bubble.left.fill",
                            color: .blue
                        )
                        StatCard(
                            value: viewModel.streak,
                            label: L10n.Progress.streakDays,
                            icon: "flame.fill",
                            color: Prep4JobTheme.amber
                        )
                    }
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "target").font(.title2).foregroundStyle(Prep4JobTheme.indigo)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.Progress.reviewToday).font(.headline.weight(.bold))
                                    .foregroundStyle(Prep4JobTheme.ink)
                                Text(L10n.Progress.reviewDescription).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                    Card {
                        Label(L10n.Progress.motivation, systemImage: "leaf.fill")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Prep4JobTheme.ink)
                    }
                }
                .padding(20)
            }
            .background(Prep4JobTheme.canvas)
        }
    }
}

struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value, format: .number).font(.title2.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
