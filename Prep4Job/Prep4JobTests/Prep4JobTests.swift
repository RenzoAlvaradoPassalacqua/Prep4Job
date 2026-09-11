//
//  Prep4JobTests.swift
//  Prep4JobTests
//
//  Created by Renzo on 10/09/26.
//

import Foundation
@testable import Prep4Job
import Testing

struct Prep4JobTests {
    @Test @MainActor
    func storeLoadsDemoContentAndRevealsAnswer() async {
        let store = PrepStore()

        await store.load()

        #expect(store.questions.count == 3)
        #expect(store.concepts.count == 4)
        #expect(store.question != nil)

        store.revealAnswer()

        #expect(store.showingAnswer)
        #expect(store.answeredQuestions.count == 1)
        #expect(store.completion > 0)
    }

    @Test @MainActor
    func storeAdvancesQuestionSafely() {
        let store = PrepStore()
        let firstQuestionID = store.question?.id

        store.nextQuestion()

        #expect(store.question?.id != firstQuestionID)
        #expect(!store.showingAnswer)
        #expect(store.savedAnswer.isEmpty)
    }

    @Test @MainActor
    func storeReportsEmptyRepositoryContent() async {
        let store = PrepStore(repository: EmptyContentRepository())

        await store.load()

        #expect(store.error == .emptyContent)
        #expect(!store.questions.isEmpty)
    }

    @Test
    func progressUseCaseCapsResultAtOne() {
        let useCase = CalculateProgressUseCase()
        let questionID = UUID()
        let conceptID = UUID()

        let progress = useCase.execute(
            answeredQuestionIDs: [questionID],
            completedConceptIDs: [conceptID],
            questionCount: 1,
            conceptCount: 1
        )

        #expect(progress == 1.0)
    }

    @Test
    func selectionUseCaseHandlesEmptyContent() {
        let useCase = SelectDailyQuestionUseCase()

        #expect(useCase.execute(questions: [], at: 0) == nil)
    }

    @Test @MainActor
    func demoAIServiceGeneratesAnswerAndConcepts() async throws {
        let service = DemoAIAnswerService()
        let question = DemoContent.questions[0]

        let answer = try await service.generateAnswer(for: question)

        #expect(!answer.text.isEmpty)
        #expect(answer.concepts == question.concepts)
    }

    @Test
    func filePersistenceRoundTripsSnapshot() async {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("prep4job-test-\(UUID().uuidString).json")
        let persistence = FileProgressPersistence(fileURL: fileURL)
        let snapshot = ProgressSnapshot(
            answeredQuestionIDs: [UUID()],
            completedConceptIDs: [UUID()],
            savedAnswer: "Respuesta de prueba",
            streak: 7
        )

        await persistence.save(snapshot)
        let restored = await persistence.load()
        try? FileManager.default.removeItem(at: fileURL)

        #expect(restored == snapshot)
    }

    @Test
    func spacedRepetitionAdvancesIntervals() {
        let scheduler = SpacedRepetitionScheduler()
        let start = Date(timeIntervalSince1970: 0)
        let schedule = scheduler.initialSchedule(
            contentID: UUID(),
            kind: .question,
            now: start
        )

        let firstReview = scheduler.review(schedule, rating: .good, now: start)
        let secondReview = scheduler.review(firstReview, rating: .good, now: start)
        let retry = scheduler.review(secondReview, rating: .again, now: start)

        #expect(firstReview.intervalDays == 1)
        #expect(secondReview.intervalDays == 3)
        #expect(secondReview.repetition == 2)
        #expect(retry.intervalDays == 1)
        #expect(retry.repetition == 0)
    }

    @Test @MainActor
    func storeTracksReviewActivityAndDueItems() async {
        let store = PrepStore(
            persistence: InMemoryProgressPersistence(),
            reminderScheduler: TestReminderScheduler()
        )

        await store.load()
        #expect(store.dueReviewCount == 7)

        store.reviewCurrentQuestion(with: .easy)

        #expect(store.answeredQuestions.count == 1)
        #expect(store.dailyActivity.first?.questionsReviewed == 1)
        #expect(store.dueReviewCount == 6)
        #expect(store.completedReviewCount == 1)
    }

    @Test @MainActor
    func storeSchedulesAndCancelsReminder() async {
        let reminderScheduler = TestReminderScheduler()
        let store = PrepStore(
            persistence: InMemoryProgressPersistence(),
            reminderScheduler: reminderScheduler
        )

        await store.setReminderEnabled(true)
        #expect(store.reminderSettings.isEnabled)
        #expect(await reminderScheduler.wasScheduled)

        await store.setReminderEnabled(false)
        #expect(!store.reminderSettings.isEnabled)
        #expect(await reminderScheduler.wasCancelled)
    }

    @Test
    func progressSnapshotDecodesLegacyPayload() throws {
        let data = Data(
            "{\"answeredQuestionIDs\":[],\"completedConceptIDs\":[],\"savedAnswer\":\"\",\"streak\":4}".utf8
        )
        let snapshot = try JSONDecoder().decode(ProgressSnapshot.self, from: data)

        #expect(snapshot.streak == 4)
        #expect(snapshot.reviewSchedules.isEmpty)
        #expect(snapshot.reminderSettings == ReminderSettings())
    }
}

private struct EmptyContentRepository: PrepContentRepository {
    func fetchQuestions() async throws -> [InterviewQuestion] {
        []
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        []
    }
}

private actor InMemoryProgressPersistence: ProgressPersistence {
    private var snapshot = ProgressSnapshot()

    func load() async -> ProgressSnapshot {
        snapshot
    }

    func save(_ snapshot: ProgressSnapshot) async {
        self.snapshot = snapshot
    }
}

private actor TestReminderScheduler: StudyReminderScheduling {
    private let granted: Bool
    private(set) var wasScheduled = false
    private(set) var wasCancelled = false

    init(granted: Bool = true) {
        self.granted = granted
    }

    func requestAuthorization() async -> Bool {
        granted
    }

    func scheduleDailyReminder(hour _: Int, minute _: Int) async throws {
        wasScheduled = true
    }

    func cancelDailyReminder() async {
        wasCancelled = true
    }
}
