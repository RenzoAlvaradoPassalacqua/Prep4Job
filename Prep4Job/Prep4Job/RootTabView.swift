import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: PrepStore

    var body: some View {
        Group {
            if !store.hasLoadedContent {
                if store.isLoading {
                    LoadingStateView()
                } else if let error = store.error {
                    ErrorStateView(message: error.localizedDescription) {
                        Task { await store.reloadContent() }
                    }
                } else {
                    LoadingStateView()
                }
            } else {
                TabView {
                    HomeView(store: store)
                        .tabItem { Label(L10n.Tabs.home, systemImage: "house.fill") }
                    LearnView(store: store)
                        .tabItem { Label(L10n.Tabs.learn, systemImage: "book.closed.fill") }
                    ProgressDashboardView(store: store)
                        .tabItem { Label(L10n.Tabs.progress, systemImage: "chart.bar.fill") }
                }
                .background(Prep4JobTheme.canvas)
            }
        }
        .background(Prep4JobTheme.canvas)
    }
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(store: PrepStore) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(L10n.Home.appName).font(.title2.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                            Text(L10n.Home.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink {
                            AccountView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                                .foregroundStyle(Prep4JobTheme.ink)
                        }
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(L10n.Home.greeting).font(.largeTitle.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                        Text(L10n.Home.intro)
                            .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 17) {
                            HStack {
                                Text(L10n.Home.todayPreparation).font(.headline.weight(.bold))
                                Spacer()
                                Label(L10n.Home.todayDate, systemImage: "calendar").font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 22) {
                                ProgressRing(value: viewModel.completion)
                                    .frame(width: 108, height: 108)
                                ChecklistView()
                            }
                            VStack(alignment: .leading, spacing: 14) {
                                ProgressRing(value: viewModel.completion)
                                    .frame(width: 108, height: 108)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                ChecklistView()
                            }
                        }
                            PrimaryButton(title: L10n.Home.start, systemImage: "arrow.right") {
                                viewModel.startSession()
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "quote.opening").font(.title2).foregroundStyle(Prep4JobTheme.violet)
                        Text(L10n.Home.quote).font(.subheadline.weight(.medium)).foregroundStyle(Prep4JobTheme.ink)
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(Prep4JobTheme.violet)
                    }
                    .padding(17)
                    .background(Prep4JobTheme.softGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Prep4JobTheme.canvas)
            .navigationDestination(isPresented: $viewModel.isSessionPresented) {
                DailyQuestionView(store: viewModel.store)
            }
        }
    }
}

struct ChecklistRow: View {
    let done: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Prep4JobTheme.mint : .gray.opacity(0.4))
            Text(text).font(.subheadline).foregroundStyle(Prep4JobTheme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
        .accessibilityValue(Text(done ? L10n.Common.completed : L10n.Common.pending))
    }
}

private struct ChecklistView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ChecklistRow(done: true, text: L10n.Home.twoConcepts)
            ChecklistRow(done: true, text: L10n.Home.oneQuestion)
            ChecklistRow(done: false, text: L10n.Home.onePractice)
            ChecklistRow(done: false, text: L10n.Home.quickReview)
        }
    }
}
