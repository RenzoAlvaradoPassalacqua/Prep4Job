//
//  Prep4JobTests.swift
//  Prep4JobTests
//
//  Created by Renzo on 10/09/26.
//

import Foundation
import Testing
@testable import Prep4Job

struct Prep4JobTests {

    @Test @MainActor
    func storeLoadsDemoContentAndRevealsAnswer() async throws {
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
    func storeAdvancesQuestionSafely() async throws {
        let store = PrepStore()
        let firstQuestionID = store.question?.id

        store.nextQuestion()

        #expect(store.question?.id != firstQuestionID)
        #expect(!store.showingAnswer)
        #expect(store.savedAnswer.isEmpty)
    }

    @Test @MainActor
    func storeReportsEmptyRepositoryContent() async throws {
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

}

private struct EmptyContentRepository: PrepContentRepository {
    func fetchQuestions() async throws -> [InterviewQuestion] { [] }
    func fetchConcepts() async throws -> [LearningConcept] { [] }
}
