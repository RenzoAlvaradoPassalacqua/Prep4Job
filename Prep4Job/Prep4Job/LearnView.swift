import SwiftUI

struct LearnView: View {
    @StateObject private var viewModel: LearnViewModel

    init(store: PrepStore) {
        _viewModel = StateObject(wrappedValue: LearnViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.Learn.title).font(.largeTitle.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                        Text(L10n.Learn.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if viewModel.concepts.isEmpty {
                        EmptyStateView(
                            title: L10n.Errors.emptyContent,
                            message: L10n.Learn.subtitle,
                            systemImage: "book.closed"
                        )
                    } else {
                        ForEach(viewModel.concepts) { concept in
                            NavigationLink {
                                ConceptDetailView(viewModel: viewModel, concept: concept)
                            } label: {
                                ConceptRow(concept: concept, completed: viewModel.isCompleted(concept))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Prep4JobTheme.canvas)
        }
    }
}

struct ConceptRow: View {
    let concept: LearningConcept
    let completed: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: completed ? "checkmark.circle.fill" : "book.closed.fill")
                .font(.title2).foregroundStyle(completed ? Prep4JobTheme.mint : Prep4JobTheme.indigo)
                .frame(width: 45, height: 45)
                .background(Prep4JobTheme.indigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(concept.title).font(.headline.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                Text(concept.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
        }
        .padding(15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(L10n.Learn.concept))
    }
}

struct ConceptDetailView: View {
    @ObservedObject var viewModel: LearnViewModel
    let concept: LearningConcept

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Label(concept.title, systemImage: "book.closed.fill")
                    .font(.largeTitle.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                Text(concept.subtitle).font(.headline).foregroundStyle(Prep4JobTheme.indigo)
                Card {
                    Text(concept.explanation).font(.subheadline).foregroundStyle(Prep4JobTheme.ink)
                }
                SectionTitle(title: L10n.Learn.howToUse)
                VStack(spacing: 0) {
                    ForEach(Array(concept.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Text("\(index + 1)").font(.caption.weight(.bold)).foregroundStyle(.white)
                                    .frame(width: 28, height: 28).background(Prep4JobTheme.indigo).clipShape(Circle())
                                if index < concept.steps.count - 1 {
                                    Rectangle().fill(Prep4JobTheme.indigo.opacity(0.25)).frame(
                                        width: 2,
                                        height: 32
                                    )
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title).font(.headline.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                                Text(step.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                PrimaryButton(
                    title: viewModel.isCompleted(concept) ? L10n.Learn.conceptCompleted : L10n.Learn
                        .markAsLearned,
                    systemImage: "checkmark"
                ) {
                    viewModel.complete(concept)
                }
            }
            .padding(20)
        }
        .background(Prep4JobTheme.canvas)
        .navigationTitle(L10n.Learn.concept)
        .navigationBarTitleDisplayMode(.inline)
    }
}
