import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel: ProgressViewModel
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
                            ForEach(Array(viewModel.weeklyActivityValues.enumerated()), id: \.offset) { index, value in
                                VStack(spacing: 7) {
                                    Capsule()
                                        .fill(index == 6 ? Prep4JobTheme.indigo : Prep4JobTheme.indigo.opacity(0.25))
                                        .frame(
                                            width: 22,
                                            height: CGFloat(max(10, 100 * value))
                                        )
                                    Text(days[index]).font(.caption2).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .bottom)
                            }
                        }
                        .frame(height: 135)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 10)], spacing: 10) {
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
                                Text(L10n.Progress.reviewToday(count: viewModel.dueReviewCount))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Prep4JobTheme.ink)
                                Text(L10n.Progress.reviewDescription).font(.caption).foregroundStyle(.secondary)
                                Text(L10n.Progress.reviewProgress(
                                    reviewed: viewModel.reviewedItemCount,
                                    total: viewModel.totalReviewItemCount
                                ))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Prep4JobTheme.indigo)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(L10n.Progress.remindersTitle, systemImage: "bell.badge.fill")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Prep4JobTheme.ink)
                            Text(
                                viewModel.reminderEnabled
                                    ? L10n.Progress.remindersEnabled
                                    : L10n.Progress.remindersDisabled
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Button(
                                viewModel.reminderEnabled
                                    ? L10n.Progress.disableReminder
                                    : L10n.Progress.enableReminder
                            ) {
                                viewModel.toggleReminder()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Prep4JobTheme.indigo)
                            if let reminderError = viewModel.reminderError {
                                InlineStatusMessage(message: reminderError)
                            }
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
