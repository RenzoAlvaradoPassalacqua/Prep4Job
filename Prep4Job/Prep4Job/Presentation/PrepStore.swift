import Combine
import Foundation

enum PrepStoreError: LocalizedError, Equatable {
    case emptyContent
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return L10n.Errors.emptyContent
        case .loadFailed:
            return L10n.Errors.loadFailed
        }
    }
}

@MainActor
final class PrepStore: ObservableObject {
    @Published private(set) var questions: [InterviewQuestion]
    @Published private(set) var concepts: [LearningConcept]
    @Published private(set) var currentQuestion = 0
    @Published private(set) var answeredQuestions: Set<UUID> = []
    @Published private(set) var completedConcepts: Set<UUID> = []
    @Published var savedAnswer = ""
    @Published private(set) var showingAnswer = false
    @Published private(set) var streak = 12
    @Published private(set) var isLoading = false
    @Published private(set) var error: PrepStoreError?

    private let loadPreparationContent: LoadPreparationContentUseCase
    private let selectDailyQuestion = SelectDailyQuestionUseCase()
    private let revealAnswerUseCase = RevealAnswerUseCase()
    private let completeConceptUseCase = CompleteConceptUseCase()
    private let calculateProgress = CalculateProgressUseCase()
    private let persistence: any ProgressPersistence
    private var hasLoaded = false

    init(
        repository: any PrepContentRepository = DemoContentRepository(),
        persistence: (any ProgressPersistence)? = nil
    ) {
        loadPreparationContent = LoadPreparationContentUseCase(repository: repository)
        self.persistence = persistence ?? ProgressPersistenceFactory.makeDefault()
        questions = DemoContent.questions
        concepts = DemoContent.concepts
    }

    var question: InterviewQuestion? {
        selectDailyQuestion.execute(questions: questions, at: currentQuestion)
    }

    var completion: Double {
        calculateProgress.execute(
            answeredQuestionIDs: answeredQuestions,
            completedConceptIDs: completedConcepts,
            questionCount: questions.count,
            conceptCount: concepts.count
        )
    }

    /// Carga contenido fuera del hilo principal y publica el resultado en MainActor.
    func load() async {
        guard !isLoading, !hasLoaded else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let fetchedContent = loadPreparationContent.execute()
            async let savedProgress = persistence.load()
            let (content, snapshot) = try await(fetchedContent, savedProgress)

            guard !content.questions.isEmpty, !content.concepts.isEmpty else {
                throw PrepStoreError.emptyContent
            }

            questions = content.questions
            concepts = content.concepts
            currentQuestion = min(currentQuestion, content.questions.count - 1)
            restore(snapshot)
            hasLoaded = true
        } catch let storeError as PrepStoreError {
            error = storeError
        } catch {
            self.error = .loadFailed
        }
    }

    func beginSession() {
        showingAnswer = false
        savedAnswer = ""
        persistProgress()
    }

    func updateSavedAnswer(_ answer: String) {
        savedAnswer = answer
        persistProgress()
    }

    func revealAnswer() {
        guard let question else { return }
        answeredQuestions = revealAnswerUseCase.execute(
            questionID: question.id,
            answeredQuestionIDs: answeredQuestions
        )
        showingAnswer = true
        persistProgress()
    }

    func nextQuestion() {
        guard !questions.isEmpty else { return }
        currentQuestion = (currentQuestion + 1) % questions.count
        showingAnswer = false
        savedAnswer = ""
        persistProgress()
    }

    func complete(_ concept: LearningConcept) {
        completedConcepts = completeConceptUseCase.execute(
            conceptID: concept.id,
            completedConceptIDs: completedConcepts
        )
        persistProgress()
    }

    private func restore(_ snapshot: ProgressSnapshot) {
        let questionIDs = Set(questions.map(\.id))
        let conceptIDs = Set(concepts.map(\.id))
        answeredQuestions = Set(snapshot.answeredQuestionIDs).intersection(questionIDs)
        completedConcepts = Set(snapshot.completedConceptIDs).intersection(conceptIDs)
        savedAnswer = snapshot.savedAnswer
        streak = snapshot.streak
    }

    private func persistProgress() {
        let snapshot = ProgressSnapshot(
            answeredQuestionIDs: Array(answeredQuestions),
            completedConceptIDs: Array(completedConcepts),
            savedAnswer: savedAnswer,
            streak: streak
        )
        let persistence = persistence
        Task {
            await persistence.save(snapshot)
        }
    }
}
