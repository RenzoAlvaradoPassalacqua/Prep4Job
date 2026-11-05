//
//  Prep4JobTests.swift
//  Prep4JobTests
//
//  Created by Renzo on 10/09/26.
//

import Combine
import Foundation
import SwiftUI
@testable import Prep4Job
import Testing

struct Prep4JobTests {
    @Test
    func contentPaginationContinuesAfterShortAndFilteredPages() async throws {
        let source = TestContentPages()
        let values: [Int] = try await ContentPageLoader().load(
            fetchPage: { cursor, limit in await source.fetch(cursor: cursor, limit: limit) },
            transform: { $0.value > 2 ? $0.value : nil }
        )
        #expect(values == [3, 4, 5])
        #expect(await source.requestCount == 4)
        #expect(await source.requestedLimits == [100, 100, 100, 100])
    }

    @Test
    func contentPaginationPropagatesLaterPageFailure() async {
        let source = TestContentPages()
        do {
            let _: [Int] = try await ContentPageLoader().load(
                fetchPage: { cursor, limit in
                    if cursor != nil { throw TestContentError.failed }
                    return await source.fetch(cursor: cursor, limit: limit)
                },
                transform: { $0.value }
            )
            Issue.record("A failed page must not return a partial catalog")
        } catch TestContentError.failed {
            #expect(await source.requestCount == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func cancelledContentPaginationDoesNotRequestPages() async {
        let source = TestContentPages()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await ContentPageLoader().load(
                fetchPage: { cursor, limit in await source.fetch(cursor: cursor, limit: limit) },
                transform: { $0.value }
            )
        }
        do {
            _ = try await task.value
            Issue.record("Cancelled loading must throw")
        } catch is CancellationError {
            #expect(await source.requestCount == 0)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }


    @Test @MainActor
    func typingDoesNotNotifySharedStoreOrFeatureViewModels() {
        let store = PrepStore(
            repository: DemoContentRepository(),
            persistence: InMemoryProgressPersistence()
        )
        let daily = DailyQuestionViewModel(store: store)
        let home = HomeViewModel(store: store)
        let learn = LearnViewModel(store: store)
        let progress = ProgressViewModel(store: store)
        var notifications = 0
        let subscriptions = [
            store.objectWillChange.sink { notifications += 1 },
            daily.objectWillChange.sink { notifications += 1 },
            home.objectWillChange.sink { notifications += 1 },
            learn.objectWillChange.sink { notifications += 1 },
            progress.objectWillChange.sink { notifications += 1 }
        ]
        defer { subscriptions.forEach { $0.cancel() } }

        daily.savedAnswerBinding.wrappedValue = "My"
        daily.savedAnswerBinding.wrappedValue = "My answer"
        #expect(store.savedAnswer == "My answer")
        #expect(daily.savedAnswerBinding.wrappedValue == "My answer")
        #expect(notifications == 0)

        daily.saveAnswer()
        #expect(daily.answerText == "My answer")
        #expect(notifications > 0)

        daily.nextQuestion()
        #expect(daily.savedAnswerBinding.wrappedValue.isEmpty)
    }


    @Test @MainActor
    func localContentIsReadyBeforeRemoteRefreshCompletes() async {
        let repository = SuspendedContentRepository()
        let store = PrepStore(
            repository: repository,
            persistence: InMemoryProgressPersistence()
        )
        let loading = Task { await store.load() }
        // Wait for local restoration, without allowing the remote request to finish.
        for _ in 0..<10_000 {
            if store.hasLoadedContent { break }
            await Task.yield()
        }
        #expect(store.hasLoadedContent)
        #expect(store.isLoading)
        #expect(!store.questions.isEmpty)
        store.updateSavedAnswer("Edited during refresh")
        await repository.release()
        await loading.value
        #expect(store.savedAnswer == "Edited during refresh")
        #expect(!store.isLoading)
        #expect(store.hasLoadedContent)
    }

    @Test @MainActor
    func storeLoadsDemoContentAndRevealsAnswer() async {
        let store = PrepStore(repository: DemoContentRepository())

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
    func dailyQuestionRatingStaysSelectedUntilAdvancing() async {
        let store = PrepStore(
            repository: DemoContentRepository(),
            persistence: InMemoryProgressPersistence()
        )
        await store.load()
        let viewModel = DailyQuestionViewModel(store: store)

        viewModel.rateCurrentQuestion(.hard)

        #expect(viewModel.selectedRating == .hard)

        viewModel.nextQuestion()

        #expect(viewModel.selectedRating == nil)
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
            repository: DemoContentRepository(),
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

    @Test
    func localAuthCreatesRestoresAndSignsOut() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("prep4job-account-(UUID().uuidString).json")
        let service = LocalAuthService(fileURL: fileURL)

        let account = try await service.signUp(
            email: "renzo@example.com",
            password: "123456",
            displayName: "Renzo"
        )
        let restored = await service.restoreSession()
        let signedIn = try await service.signIn(email: account.email, password: "123456")

        #expect(restored == account)
        #expect(signedIn == account)

        await service.signOut()
        #expect(await service.restoreSession() == nil)
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test
    func supabaseSessionResponseDecodesTopLevelAccessToken() throws {
        let data = Data("""
        {
          "access_token": "top-level-token",
          "user": {
            "id": "00000000-0000-0000-0000-000000000001",
            "email": "renzo@example.com",
            "created_at": "2026-09-11T12:00:00Z",
            "user_metadata": { "display_name": "Renzo" }
          }
        }
        """.utf8)

        let payload = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)

        #expect(payload.accessToken == "top-level-token")
        #expect(payload.user?.account?.displayName == "Renzo")
    }

    @Test
    func supabaseSessionResponseDecodesNestedSessionAccessToken() throws {
        let data = Data("""
        {
          "session": {
            "access_token": "nested-token",
            "user": {
              "id": "00000000-0000-0000-0000-000000000002",
              "email": "renzo@example.com",
              "created_at": "2026-09-11T12:00:00Z",
              "user_metadata": { "display_name": "Renzo" }
            }
          }
        }
        """.utf8)

        let payload = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)

        #expect(payload.accessToken == "nested-token")
        #expect(payload.user?.account?.email == "renzo@example.com")
    }

    @Test
    func supabaseSignUpConfirmationResponseHasNoAccessToken() throws {
        let data = Data("""
        {
          "user": {
            "id": "00000000-0000-0000-0000-000000000003",
            "email": "renzo@example.com",
            "created_at": "2026-09-11T12:00:00Z",
            "user_metadata": { "display_name": "Renzo" }
          },
          "session": null
        }
        """.utf8)

        let payload = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)

        #expect(payload.accessToken == nil)
        #expect(payload.user?.account?.email == "renzo@example.com")
    }

    @Test
    func demoSubscriptionActivatesPremium() async throws {
        let service = DemoSubscriptionService()
        let products = try await service.products()
        let entitlement = try await service.purchase(productID: products[0].id)

        #expect(products.count == 2)
        #expect(entitlement.isActive)
        #expect((await service.currentEntitlement()).isActive)
    }
}

nonisolated private enum TestContentError: Error {
    case failed
}

nonisolated private struct TestContentRow: Identifiable, Sendable {
    let id: UUID
    let value: Int
}

private actor TestContentPages {
    private let rows: [TestContentRow] = (1...5).map { value in
        TestContentRow(id: UUID(), value: value)
    }
    private(set) var requestCount = 0
    private(set) var requestedLimits: [Int] = []

    func fetch(cursor: UUID?, limit: Int) -> [TestContentRow] {
        requestCount += 1
        requestedLimits.append(limit)
        let start = cursor.flatMap { id in rows.firstIndex { $0.id == id } }.map { $0 + 1 } ?? 0
        // Simulate a server cap below the requested page size.
        return Array(rows.dropFirst(start).prefix(min(limit, 2)))
    }
}

private actor SuspendedContentRepository: PrepContentRepository {
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?

    func fetchQuestions() async throws -> [InterviewQuestion] {
        if !released {
            await withCheckedContinuation { continuation = $0 }
        }
        return await DemoContent.questions
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        await DemoContent.concepts
    }

    func release() {
        released = true
        continuation?.resume()
        continuation = nil
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
