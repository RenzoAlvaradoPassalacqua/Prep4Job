import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: PrepStore

    var body: some View {
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
                        Image(systemName: "bell.badge").font(.title3).foregroundStyle(Prep4JobTheme.ink)
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
                            HStack(spacing: 22) {
                                ProgressRing(value: 0.72).frame(width: 108, height: 108)
                                VStack(alignment: .leading, spacing: 11) {
                                    ChecklistRow(done: true, text: L10n.Home.twoConcepts)
                                    ChecklistRow(done: true, text: L10n.Home.oneQuestion)
                                    ChecklistRow(done: false, text: L10n.Home.onePractice)
                                    ChecklistRow(done: false, text: L10n.Home.quickReview)
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
    }
}
