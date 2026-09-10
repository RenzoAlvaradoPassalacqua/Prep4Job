import Foundation

nonisolated struct AIAnswer: Codable, Equatable, Sendable {
    let text: String
    let concepts: [String]
}

nonisolated enum AIAnswerState: Equatable, Sendable {
    case idle
    case loading
    case loaded(AIAnswer)
    case failed(String)

    var answer: AIAnswer? {
        guard case let .loaded(answer) = self else { return nil }
        return answer
    }

    var isLoaded: Bool {
        answer != nil
    }
}

nonisolated protocol AIAnswerService: Sendable {
    func generateAnswer(for question: InterviewQuestion) async throws -> AIAnswer
}

nonisolated enum AIAnswerServiceError: LocalizedError, Equatable {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.Errors.aiAnswerUnavailable
        }
    }
}

/// Implementación local para el MVP. Simula la latencia de IA y puede
/// sustituirse por un cliente HTTP sin modificar el ViewModel.
nonisolated struct DemoAIAnswerService: AIAnswerService {
    func generateAnswer(for question: InterviewQuestion) async throws -> AIAnswer {
        try await Task.sleep(for: .milliseconds(350))
        try Task.checkCancellation()

        guard !question.answer.isEmpty else {
            throw AIAnswerServiceError.invalidResponse
        }

        return AIAnswer(text: question.answer, concepts: question.concepts)
    }
}
