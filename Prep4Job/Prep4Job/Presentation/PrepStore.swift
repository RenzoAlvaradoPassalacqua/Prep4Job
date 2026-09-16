import Combine
@preconcurrency import Foundation

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
    @Published private(set) var reviewSchedules: [UUID: ReviewSchedule] = [:]
    @Published private(set) var dailyActivity: [DailyActivity] = []
    @Published private(set) var reminderSettings = ReminderSettings()
    @Published private(set) var reminderError: String?
    @Published private(set) var totalStudySessions = 0
    @Published private(set) var lastStudyDate: Date?

    private let loadPreparationContent: LoadPreparationContentUseCase
    private let selectDailyQuestion = SelectDailyQuestionUseCase()
    private let revealAnswerUseCase = RevealAnswerUseCase()
    private let completeConceptUseCase = CompleteConceptUseCase()
    private let calculateProgress = CalculateProgressUseCase()
    private let repetitionScheduler = SpacedRepetitionScheduler()
    private let persistence: any ProgressPersistence
    private let reminderScheduler: any StudyReminderScheduling
    private var hasLoaded = false
    private var persistenceTask: Task<Void, Never>?
    private var notificationObservers: [NSObjectProtocol] = []

    init(
        repository: (any PrepContentRepository)? = nil,
        persistence: (any ProgressPersistence)? = nil,
        reminderScheduler: (any StudyReminderScheduling)? = nil
    ) {
        let contentRepository = repository ?? ContentRepositoryFactory.makeDefault()
        loadPreparationContent = LoadPreparationContentUseCase(repository: contentRepository)
        self.persistence = persistence ?? ProgressPersistenceFactory.makeDefault()
        self.reminderScheduler = reminderScheduler ?? LocalNotificationScheduler()
        questions = DemoContent.questions
        concepts = DemoContent.concepts
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(
            forName: .prep4jobAuthStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.reloadContent() }
        })
        notificationObservers.append(center.addObserver(
            forName: .prep4jobEntitlementDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.reloadContent() }
        })
    }

    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }

    var question: InterviewQuestion? {
        selectDailyQuestion.execute(questions: questions, at: currentQuestion)
    }

    var hasLoadedContent: Bool {
        hasLoaded
    }

    var completion: Double {
        calculateProgress.execute(
            answeredQuestionIDs: answeredQuestions,
            completedConceptIDs: completedConcepts,
            questionCount: questions.count,
            conceptCount: concepts.count
        )
    }

    var dueReviewCount: Int {
        reviewSchedules.values.filter { $0.dueDate <= Date() }.count
    }

    var completedReviewCount: Int {
        reviewSchedules.values.filter { $0.repetition > 0 }.count
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
            seedMissingSchedules()
            hasLoaded = true
        } catch let storeError as PrepStoreError {
            error = storeError
            // Keep the last known content available so the app remains usable offline.
            hasLoaded = !questions.isEmpty && !concepts.isEmpty
        } catch {
            self.error = .loadFailed
            // Keep the last known content available so the app remains usable offline.
            hasLoaded = !questions.isEmpty && !concepts.isEmpty
        }
    }

    func reloadContent() async {
        hasLoaded = false
        await load()
    }

    func beginSession() {
        showingAnswer = false
        savedAnswer = ""
        totalStudySessions += 1
        persistProgress()
    }

    func updateSavedAnswer(_ answer: String) {
        savedAnswer = answer
        if let question {
            var answers = currentSavedAnswers
            answers[question.id] = answer
            currentSavedAnswers = answers
        }
        persistProgress()
    }

    func revealAnswer() {
        guard let question else { return }
        answeredQuestions = revealAnswerUseCase.execute(
            questionID: question.id,
            answeredQuestionIDs: answeredQuestions
        )
        showingAnswer = true
        persistProgress(syncRemote: true, changedID: question.id, kind: .question)
    }

    func reviewCurrentQuestion(with rating: ReviewRating) {
        guard let question else { return }
        answeredQuestions = revealAnswerUseCase.execute(
            questionID: question.id,
            answeredQuestionIDs: answeredQuestions
        )
        showingAnswer = true
        reviewItem(id: question.id, kind: .question, rating: rating)
    }

    func nextQuestion() {
        guard !questions.isEmpty else { return }
        let previousQuestionID = question?.id
        currentQuestion = (currentQuestion + 1) % questions.count
        showingAnswer = false
        savedAnswer = ""
        persistProgress(
            syncRemote: previousQuestionID != nil,
            changedID: previousQuestionID,
            kind: .question
        )
    }

    func complete(_ concept: LearningConcept) {
        let wasCompleted = completedConcepts.contains(concept.id)
        completedConcepts = completeConceptUseCase.execute(
            conceptID: concept.id,
            completedConceptIDs: completedConcepts
        )
        reviewItem(
            id: concept.id,
            kind: .concept,
            rating: .good,
            shouldRecordActivity: !wasCompleted
        )
    }

    func setReminderEnabled(_ enabled: Bool) async {
        reminderError = nil

        if enabled {
            let granted = await reminderScheduler.requestAuthorization()
            guard granted else {
                reminderSettings.isEnabled = false
                reminderError = L10n.Errors.notificationsDenied
                persistProgress()
                return
            }

            do {
                try await reminderScheduler.scheduleDailyReminder(
                    hour: reminderSettings.hour,
                    minute: reminderSettings.minute
                )
                reminderSettings.isEnabled = true
            } catch {
                reminderSettings.isEnabled = false
                reminderError = L10n.Errors.notificationsUnavailable
            }
        } else {
            await reminderScheduler.cancelDailyReminder()
            reminderSettings.isEnabled = false
        }

        persistProgress()
    }

    private var currentSavedAnswers: [UUID: String] {
        get { savedAnswerStore }
        set { savedAnswerStore = newValue }
    }

    private var savedAnswerStore: [UUID: String] = [:]
}

private extension PrepStore {
    func restore(_ snapshot: ProgressSnapshot) {
        let questionIDs = Set(questions.map(\.id))
        let conceptIDs = Set(concepts.map(\.id))
        answeredQuestions = Set(snapshot.answeredQuestionIDs).intersection(questionIDs)
        completedConcepts = Set(snapshot.completedConceptIDs).intersection(conceptIDs)
        savedAnswer = snapshot.savedAnswer
        savedAnswerStore = snapshot.savedAnswers
        streak = snapshot.streak
        let validIDs = questionIDs.union(conceptIDs)
        reviewSchedules = Dictionary(
            uniqueKeysWithValues: snapshot.reviewSchedules
                .filter { validIDs.contains($0.contentID) }
                .map { ($0.contentID, $0) }
        )
        dailyActivity = snapshot.dailyActivity.sorted { $0.date < $1.date }
        reminderSettings = snapshot.reminderSettings
        totalStudySessions = snapshot.totalStudySessions
    }

    func seedMissingSchedules() {
        var schedules = reviewSchedules
        let now = Date()

        for question in questions where schedules[question.id] == nil {
            schedules[question.id] = repetitionScheduler.initialSchedule(
                contentID: question.id,
                kind: .question,
                now: now
            )
        }
        for concept in concepts where schedules[concept.id] == nil {
            schedules[concept.id] = repetitionScheduler.initialSchedule(
                contentID: concept.id,
                kind: .concept,
                now: now
            )
        }
        reviewSchedules = schedules
    }

    func reviewItem(
        id: UUID,
        kind: ReviewItemKind,
        rating: ReviewRating,
        shouldRecordActivity: Bool = true
    ) {
        let schedule = reviewSchedules[id] ?? repetitionScheduler.initialSchedule(
            contentID: id,
            kind: kind
        )
        reviewSchedules[id] = repetitionScheduler.review(schedule, rating: rating)
        if shouldRecordActivity {
            recordActivity(for: kind)
        }
        persistProgress(syncRemote: true, changedID: id, kind: kind)
    }

    func recordActivity(for kind: ReviewItemKind, at date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        if let index = dailyActivity.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
        }) {
            switch kind {
            case .question:
                dailyActivity[index].questionsReviewed += 1
            case .concept:
                dailyActivity[index].conceptsReviewed += 1
            }
        } else {
            var activity = DailyActivity(date: day)
            switch kind {
            case .question:
                activity.questionsReviewed = 1
            case .concept:
                activity.conceptsReviewed = 1
            }
            dailyActivity.append(activity)
        }
        dailyActivity = Array(dailyActivity.sorted { $0.date < $1.date }.suffix(30))
        updateStreak(for: day)
    }

    func updateStreak(for day: Date) {
        guard let lastStudyDate else {
            streak = 1
            lastStudyDate = day
            return
        }

        let calendar = Calendar.current
        if calendar.isDate(lastStudyDate, inSameDayAs: day) {
            return
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: day)
        streak = yesterday.map { calendar.isDate(lastStudyDate, inSameDayAs: $0) ? streak + 1 : 1 } ?? 1
        self.lastStudyDate = day
    }

    func persistProgress(
        syncRemote: Bool = false,
        changedID: UUID? = nil,
        kind: ReviewItemKind? = nil
    ) {
        let snapshot = ProgressSnapshot(
            answeredQuestionIDs: Array(answeredQuestions),
            completedConceptIDs: Array(completedConcepts),
            savedAnswer: savedAnswer,
            savedAnswers: currentSavedAnswers,
            streak: streak,
            reviewSchedules: Array(reviewSchedules.values),
            dailyActivity: dailyActivity,
            reminderSettings: reminderSettings,
            lastStudyDate: lastStudyDate,
            totalStudySessions: totalStudySessions
        )
        persistenceTask?.cancel()
        let persistence = persistence
        persistenceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await persistence.save(snapshot)
            guard syncRemote, let changedID, let kind else { return }
            await SupabaseProgressSync.shared.save(snapshot, contentID: changedID, kind: kind)
        }
    }
}
