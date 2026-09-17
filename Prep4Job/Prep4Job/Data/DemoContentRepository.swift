import Foundation
import Supabase

nonisolated protocol PrepContentRepository: Sendable {
    func fetchQuestions() async throws -> [InterviewQuestion]
    func fetchConcepts() async throws -> [LearningConcept]
}

/// Fuente local de contenido para el MVP. En producción puede sustituirse por
/// una implementación remota sin modificar la capa de presentación.
struct DemoContentRepository: PrepContentRepository {
    func fetchQuestions() async throws -> [InterviewQuestion] {
        await DemoContent.questions
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        await DemoContent.concepts
    }
}

/// Remote content source. Falls back to the demo repository when configuration is absent.
struct SupabaseContentRepository: PrepContentRepository {
    private let client: SupabaseClient

    init?(client: SupabaseClient? = nil) {
        guard let client = client ?? SupabaseClientFactory.make() else { return nil }
        self.client = client
    }

    func fetchQuestions() async throws -> [InterviewQuestion] {
        let rows: [RemoteQuestion] = try await client
            .from("interview_questions")
            .select()
            .execute()
            .value
        return await MainActor.run {
            rows.map { $0.model }
        }
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        let rows: [RemoteConcept] = try await client
            .from("learning_concepts")
            .select()
            .execute()
            .value
        return await MainActor.run {
            rows.map { $0.model }
        }
    }

}

private struct RemoteQuestion: Decodable {
    let id: UUID
    let category: String
    let question: String
    let answer: String
    let concepts: [String]
    let purpose: String
    let tip: String

    var model: InterviewQuestion {
        InterviewQuestion(
            id: id,
            title: question,
            category: category,
            purpose: purpose,
            tip: tip,
            answer: answer,
            concepts: concepts
        )
    }
}

private struct RemoteConcept: Decodable {
    let id: UUID
    let title: String
    let summary: String
    let detail: String

    var model: LearningConcept {
        LearningConcept(id: id, title: title, subtitle: summary, explanation: detail, steps: [], color: .indigo)
    }
}

enum ContentRepositoryFactory {
    static func makeDefault() -> any PrepContentRepository {
        SupabaseContentRepository() ?? DemoContentRepository()
    }
}

enum DemoContent {
    static let questions: [InterviewQuestion] = [
        InterviewQuestion(
            id: stableID("00000000-0000-0000-0000-000000000001"),
            title: L10n.Questions.conflictTitle,
            category: L10n.Questions.behavioral,
            purpose: L10n.Questions.conflictPurpose,
            tip: L10n.Questions.conflictTip,
            answer: L10n.Questions.conflictAnswer,
            concepts: [L10n.Concepts.star, L10n.Questions.leadership, L10n.Questions.conflictResolution]
        ),
        InterviewQuestion(
            id: stableID("00000000-0000-0000-0000-000000000002"),
            title: L10n.Questions.proudProjectTitle,
            category: L10n.Questions.experience,
            purpose: L10n.Questions.proudProjectPurpose,
            tip: L10n.Questions.proudProjectTip,
            answer: L10n.Questions.proudProjectAnswer,
            concepts: [L10n.Questions.measurableImpact, L10n.Questions.prioritization, L10n.Questions.collaboration]
        ),
        InterviewQuestion(
            id: stableID("00000000-0000-0000-0000-000000000003"),
            title: L10n.Questions.technicalProblemTitle,
            category: L10n.Questions.problemSolving,
            purpose: L10n.Questions.technicalProblemPurpose,
            tip: L10n.Questions.technicalProblemTip,
            answer: L10n.Questions.technicalProblemAnswer,
            concepts: [
                L10n.Questions.structuredThinking,
                L10n.Concepts.communication,
                L10n.Questions.continuousLearning
            ]
        )
    ]

    static let concepts: [LearningConcept] = [
        LearningConcept(
            id: stableID("10000000-0000-0000-0000-000000000001"),
            title: L10n.Concepts.star,
            subtitle: L10n.Concepts.starSubtitle,
            explanation: L10n.Concepts.starExplanation,
            steps: [
                LearningStep(title: L10n.Concepts.situation, detail: L10n.Concepts.situationDetail),
                LearningStep(title: L10n.Concepts.task, detail: L10n.Concepts.taskDetail),
                LearningStep(title: L10n.Concepts.action, detail: L10n.Concepts.actionDetail),
                LearningStep(title: L10n.Concepts.result, detail: L10n.Concepts.resultDetail)
            ],
            color: .indigo
        ),
        LearningConcept(
            id: stableID("10000000-0000-0000-0000-000000000002"),
            title: L10n.Concepts.measurableImpact,
            subtitle: L10n.Concepts.measurableImpactSubtitle,
            explanation: L10n.Concepts.measurableImpactExplanation,
            steps: [
                LearningStep(title: L10n.Concepts.before, detail: L10n.Concepts.beforeDetail),
                LearningStep(title: L10n.Concepts.change, detail: L10n.Concepts.changeDetail),
                LearningStep(title: L10n.Concepts.after, detail: L10n.Concepts.afterDetail)
            ],
            color: .mint
        ),
        LearningConcept(
            id: stableID("10000000-0000-0000-0000-000000000003"),
            title: L10n.Concepts.structuredThinking,
            subtitle: L10n.Concepts.structuredThinkingSubtitle,
            explanation: L10n.Concepts.structuredThinkingExplanation,
            steps: [
                LearningStep(title: L10n.Concepts.clarify, detail: L10n.Concepts.clarifyDetail),
                LearningStep(title: L10n.Concepts.divide, detail: L10n.Concepts.divideDetail),
                LearningStep(title: L10n.Concepts.validate, detail: L10n.Concepts.validateDetail)
            ],
            color: .violet
        ),
        LearningConcept(
            id: stableID("10000000-0000-0000-0000-000000000004"),
            title: L10n.Concepts.communication,
            subtitle: L10n.Concepts.communicationSubtitle,
            explanation: L10n.Concepts.communicationExplanation,
            steps: [
                LearningStep(title: L10n.Concepts.listen, detail: L10n.Concepts.listenDetail),
                LearningStep(title: L10n.Concepts.align, detail: L10n.Concepts.alignDetail),
                LearningStep(title: L10n.Concepts.act, detail: L10n.Concepts.actDetail)
            ],
            color: .amber
        )
    ]

    private static func stableID(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }
}
