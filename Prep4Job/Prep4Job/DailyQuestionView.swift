import SwiftUI

struct DailyQuestionView: View {
    @StateObject private var viewModel: DailyQuestionViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: PrepStore) {
        _viewModel = StateObject(wrappedValue: DailyQuestionViewModel(store: store))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                if let question = viewModel.question {
                    HStack {
                        Text(L10n.DailyQuestion.counter(
                            current: viewModel.currentQuestion + 1,
                            total: viewModel.questionCount
                        ))
                        .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Spacer()
                        Text(question.category).font(.caption.weight(.semibold)).foregroundStyle(Prep4JobTheme.indigo)
                    }
                    ProgressView(
                        value: Double(viewModel.currentQuestion + 1),
                        total: Double(viewModel.questionCount)
                    )
                    .tint(Prep4JobTheme.violet)

                    Text(question.title)
                        .font(.title2.weight(.bold)).foregroundStyle(Prep4JobTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Card {
                        Label {
                            Text(question.purpose).font(.subheadline).foregroundStyle(Prep4JobTheme.ink)
                        } icon: {
                            Image(systemName: "bubble.left.and.bubble.right.fill").foregroundStyle(Prep4JobTheme.indigo)
                        }
                    }

                    Card {
                        Label(L10n.DailyQuestion.tip, systemImage: "lightbulb.fill")
                            .font(.headline.weight(.bold)).foregroundStyle(Prep4JobTheme.indigo)
                        Text(question.tip).font(.subheadline).foregroundStyle(.secondary).padding(.top, 6)
                    }

                    switch viewModel.answerState {
                    case .loaded:
                        AnswerCard(viewModel: viewModel, question: question)
                    case .loading:
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Prep4JobTheme.indigo)
                            Text(L10n.DailyQuestion.generatingAnswer)
                                .font(.subheadline).foregroundStyle(.secondary)
                            Button(L10n.DailyQuestion.cancelGeneration) {
                                viewModel.cancelGeneration()
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    case let .failed(message):
                        VStack(alignment: .leading, spacing: 10) {
                            Text(message)
                                .font(.subheadline).foregroundStyle(.secondary)
                            Button {
                                viewModel.generateAnswer()
                            } label: {
                                Label(L10n.DailyQuestion.retryAnswer, systemImage: "arrow.clockwise")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    case .idle:
                        VStack(spacing: 10) {
                            Button {
                                viewModel.generateAnswer()
                            } label: {
                                Label(L10n.DailyQuestion.showAIAnswer, systemImage: "sparkles")
                                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .foregroundStyle(.white).background(Prep4JobTheme.indigo)
                                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                AnswerEditorView(viewModel: viewModel)
                            } label: {
                                Label(L10n.DailyQuestion.writeAnswer, systemImage: "pencil")
                                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .foregroundStyle(Prep4JobTheme.indigo)
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(
                                        Prep4JobTheme.indigo,
                                        lineWidth: 1.2
                                    ))
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label(L10n.DailyQuestion.emptyTitle, systemImage: "questionmark.circle")
                    } description: {
                        Text(L10n.DailyQuestion.emptyMessage)
                    }
                }
            }
            .padding(20)
        }
        .background(Prep4JobTheme.canvas)
        .navigationTitle(L10n.DailyQuestion.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button(L10n.DailyQuestion.close) { dismiss() } }
        }
    }
}

struct AnswerCard: View {
    @ObservedObject var viewModel: DailyQuestionViewModel
    let question: InterviewQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.DailyQuestion.recommendedAnswer, systemImage: "sparkles")
                .font(.headline.weight(.bold)).foregroundStyle(Prep4JobTheme.indigo)
            Text(L10n.DailyQuestion.answerDescription)
                .font(.subheadline).foregroundStyle(.secondary)
            Text(viewModel.answerText).font(.subheadline).foregroundStyle(Prep4JobTheme.ink)
            HStack(spacing: 8) {
                ForEach(viewModel.answerConcepts, id: \.self) { concept in
                    Text(concept).font(.caption.weight(.medium)).foregroundStyle(Prep4JobTheme.indigo)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Prep4JobTheme.indigo.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            NavigationLink {
                AnswerEditorView(viewModel: viewModel)
            } label: {
                Label(L10n.DailyQuestion.personalize, systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
                    .foregroundStyle(.white).background(Prep4JobTheme.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(18)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct AnswerEditorView: View {
    @ObservedObject var viewModel: DailyQuestionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.DailyQuestion.editorHint)
                .font(.subheadline).foregroundStyle(.secondary)
            TextEditor(text: viewModel.savedAnswerBinding)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15)))
            PrimaryButton(title: L10n.DailyQuestion.saveAnswer, systemImage: "checkmark") {
                viewModel.saveAnswer()
                dismiss()
            }
            Spacer()
        }
        .padding(20)
        .background(Prep4JobTheme.canvas)
        .navigationTitle(L10n.DailyQuestion.myAnswer)
        .navigationBarTitleDisplayMode(.inline)
    }
}
