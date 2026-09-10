import Foundation

nonisolated struct PreparationContent: Sendable {
    let questions: [InterviewQuestion]
    let concepts: [LearningConcept]
}

nonisolated struct LoadPreparationContentUseCase: Sendable {
    private let repository: any PrepContentRepository

    init(repository: any PrepContentRepository) {
        self.repository = repository
    }

    func execute() async throws -> PreparationContent {
        async let questions = repository.fetchQuestions()
        async let concepts = repository.fetchConcepts()
        return try await PreparationContent(questions: questions, concepts: concepts)
    }
}

nonisolated struct SelectDailyQuestionUseCase: Sendable {
    func execute(questions: [InterviewQuestion], at index: Int) -> InterviewQuestion? {
        guard !questions.isEmpty else { return nil }
        return questions[index % questions.count]
    }
}

nonisolated struct RevealAnswerUseCase: Sendable {
    func execute(questionID: UUID, answeredQuestionIDs: Set<UUID>) -> Set<UUID> {
        answeredQuestionIDs.union([questionID])
    }
}

nonisolated struct CompleteConceptUseCase: Sendable {
    func execute(conceptID: UUID, completedConceptIDs: Set<UUID>) -> Set<UUID> {
        completedConceptIDs.union([conceptID])
    }
}

nonisolated struct CalculateProgressUseCase: Sendable {
    func execute(
        answeredQuestionIDs: Set<UUID>,
        completedConceptIDs: Set<UUID>,
        questionCount: Int,
        conceptCount: Int
    ) -> Double {
        let totalItems = questionCount + conceptCount
        guard totalItems > 0 else { return 0 }

        let completedItems = answeredQuestionIDs.count + completedConceptIDs.count
        return min(Double(completedItems) / Double(totalItems), 1.0)
    }
}
