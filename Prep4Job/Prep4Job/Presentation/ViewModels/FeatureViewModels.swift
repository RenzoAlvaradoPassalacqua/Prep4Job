import Combine
import SwiftUI

@MainActor
class StoreViewModel: ObservableObject {
    let store: PrepStore
    private var cancellables = Set<AnyCancellable>()

    init(store: PrepStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

@MainActor
final class HomeViewModel: StoreViewModel {
    @Published var isSessionPresented = false

    var completion: Double {
        store.completion
    }

    func startSession() {
        store.beginSession()
        isSessionPresented = true
    }
}

@MainActor
final class DailyQuestionViewModel: StoreViewModel {
    private let answerService: any AIAnswerService
    private var generationTask: Task<Void, Never>?
    @Published private(set) var answerState: AIAnswerState = .idle

    init(
        store: PrepStore,
        answerService: any AIAnswerService = DemoAIAnswerService()
    ) {
        self.answerService = answerService
        super.init(store: store)
    }

    var question: InterviewQuestion? {
        store.question
    }

    var currentQuestion: Int {
        store.currentQuestion
    }

    var questionCount: Int {
        store.questions.count
    }

    var showingAnswer: Bool {
        store.showingAnswer || answerState.isLoaded
    }

    var answerText: String {
        answerState.answer?.text ?? question?.answer ?? ""
    }

    var answerConcepts: [String] {
        answerState.answer?.concepts ?? question?.concepts ?? []
    }

    var savedAnswerBinding: Binding<String> {
        Binding(
            get: { self.store.savedAnswer },
            set: { self.store.updateSavedAnswer($0) }
        )
    }

    func generateAnswer() {
        generationTask?.cancel()
        generationTask = Task { [weak self] in
            await self?.performGeneration()
        }
    }

    func saveAnswer() {
        let answer = store.savedAnswer.isEmpty ? question?.answer ?? "" : store.savedAnswer
        store.revealAnswer()
        answerState = .loaded(AIAnswer(text: answer, concepts: question?.concepts ?? []))
    }

    func rateCurrentQuestion(_ rating: ReviewRating) {
        store.reviewCurrentQuestion(with: rating)
    }

    func nextQuestion() {
        store.nextQuestion()
        answerState = .idle
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        answerState = .idle
    }

    private func performGeneration() async {
        guard let question else { return }
        answerState = .loading

        do {
            let answer = try await answerService.generateAnswer(for: question)
            try Task.checkCancellation()
            answerState = .loaded(answer)
            store.revealAnswer()
        } catch is CancellationError {
            answerState = .idle
        } catch {
            answerState = .failed(error.localizedDescription)
        }
    }
}

@MainActor
final class LearnViewModel: StoreViewModel {
    var concepts: [LearningConcept] {
        store.concepts
    }

    var completedConcepts: Set<UUID> {
        store.completedConcepts
    }

    func isCompleted(_ concept: LearningConcept) -> Bool {
        completedConcepts.contains(concept.id)
    }

    func complete(_ concept: LearningConcept) {
        store.complete(concept)
    }
}

@MainActor
final class ProgressViewModel: StoreViewModel {
    var completedConceptCount: Int {
        store.completedConcepts.count
    }

    var answeredQuestionCount: Int {
        store.answeredQuestions.count
    }

    var streak: Int {
        store.streak
    }

    var completion: Double {
        store.completion
    }

    var dueReviewCount: Int {
        store.dueReviewCount
    }

    var reviewedItemCount: Int {
        store.completedReviewCount
    }

    var totalReviewItemCount: Int {
        store.reviewSchedules.count
    }

    var reminderEnabled: Bool {
        store.reminderSettings.isEnabled
    }

    var reminderError: String? {
        store.reminderError
    }

    var weeklyActivityValues: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0 ..< 7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return 0 }
            let activity = store.dailyActivity.first {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            return min(Double(activity?.totalReviews ?? 0) / 4.0, 1.0)
        }
    }

    func toggleReminder() {
        let shouldEnable = !store.reminderSettings.isEnabled
        Task { await store.setReminderEnabled(shouldEnable) }
    }
}
