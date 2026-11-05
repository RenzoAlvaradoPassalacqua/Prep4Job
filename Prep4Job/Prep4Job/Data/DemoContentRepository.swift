import Foundation
import Supabase

nonisolated protocol PrepContentRepository: Sendable {
    func fetchQuestions() async throws -> [InterviewQuestion]
    func fetchConcepts() async throws -> [LearningConcept]
}

protocol PremiumAccessPolicy: Sendable {
    var isPremium: Bool { get }
}

struct AlwaysFreePolicy: PremiumAccessPolicy {
    let isPremium = false
}

/// Fuente local de contenido para el MVP. En producción puede sustituirse por
/// una implementación remota sin modificar la capa de presentación.
struct DemoContentRepository: PrepContentRepository {
    private let policy: PremiumAccessPolicy

    init(policy: PremiumAccessPolicy = AlwaysFreePolicy()) {
        self.policy = policy
    }

    func fetchQuestions() async throws -> [InterviewQuestion] {
        // Capture premium flag outside of the nonisolated closure to avoid actor isolation warning
        let isPremium: Bool = await MainActor.run { policy.isPremium }
        return await DemoContent.questions.filter { !$0.requiresPremium || isPremium }
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        await DemoContent.concepts
    }
}

/// Remote content source. Falls back to the demo repository when configuration is absent.
struct SupabaseContentRepository: PrepContentRepository {
    private let client: SupabaseClient
    private let policy: PremiumAccessPolicy

    init?(client: SupabaseClient? = nil, policy: PremiumAccessPolicy = AlwaysFreePolicy()) {
        guard let client = client ?? SupabaseClientFactory.make() else { return nil }
        self.client = client
        self.policy = policy
    }

    func fetchQuestions() async throws -> [InterviewQuestion] {
        let isPremium = await MainActor.run { policy.isPremium }
        return try await ContentPageLoader().load(
            fetchPage: { [client] cursor, limit in
                var query = client.from("interview_questions").select()
                if let cursor {
                    query = query.gt("id", value: cursor.uuidString)
                }
                let rows: [RemoteQuestion] = try await query
                    .order("id", ascending: true)
                    .limit(limit)
                    .execute()
                    .value
                return rows
            },
            transform: { row in
                guard !(row.requiresPremium ?? false) || isPremium else { return nil }
                return row.model
            }
        )
    }

    func fetchConcepts() async throws -> [LearningConcept] {
        try await ContentPageLoader().load(
            fetchPage: { [client] cursor, limit in
                var query = client.from("learning_concepts").select()
                if let cursor {
                    query = query.gt("id", value: cursor.uuidString)
                }
                let rows: [RemoteConcept] = try await query
                    .order("id", ascending: true)
                    .limit(limit)
                    .execute()
                    .value
                return rows
            },
            transform: { $0.model }
        )
    }

}

nonisolated private struct RemoteQuestion: Decodable, Identifiable, Sendable {
    let id: UUID
    let category: String
    let question: String
    let answer: String
    let concepts: [String]
    let purpose: String
    let tip: String
    let requiresPremium: Bool?

    var model: InterviewQuestion {
        InterviewQuestion(
            id: id,
            title: question,
            category: category,
            purpose: purpose,
            tip: tip,
            answer: answer,
            concepts: concepts,
            requiresPremium: requiresPremium ?? false
        )
    }
}

nonisolated private struct RemoteConcept: Decodable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let summary: String
    let detail: String

    var model: LearningConcept {
        LearningConcept(id: id, title: title, subtitle: summary, explanation: detail, steps: [], color: .indigo)
    }
}

// Actor isolation keeps page conversion and accumulation off the UI actor.
actor ContentPageLoader {
    enum PaginationError: Error {
        case cursorDidNotAdvance
    }

    func load<Row: Identifiable & Sendable, Model: Sendable>(
        fetchPage: @Sendable (UUID?, Int) async throws -> [Row],
        transform: @Sendable (Row) -> Model?
    ) async throws -> [Model] where Row.ID == UUID {
        var cursor: UUID?
        var models: [Model] = []
        while true {
            try Task.checkCancellation()
            let rows = try await fetchPage(cursor, 100)
            try Task.checkCancellation()
            guard let last = rows.last else { return models }
            guard last.id != cursor else { throw PaginationError.cursorDidNotAdvance }
            models.append(contentsOf: rows.compactMap(transform))
            cursor = last.id
            // A short page can be a server cap. Only an empty page ends the load.
            // Advance using raw rows even when every row is filtered out.
        }
    }
}

enum ContentRepositoryFactory {
    static func makeDefault(premiumPolicy: PremiumAccessPolicy = AlwaysFreePolicy()) -> any PrepContentRepository {
        SupabaseContentRepository(policy: premiumPolicy) ?? DemoContentRepository(policy: premiumPolicy)
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
        ),
        InterviewQuestion(
            id: stableID("00000000-0000-0000-0000-000000000004"),
            title: "Handling Ambiguous Requirements",
            category: L10n.Questions.problemSolving,
            purpose: "Demonstrate how you manage unclear project requirements.",
            tip: "Clarify assumptions and communicate proactively.",
            answer: "I start by asking clarifying questions and engage stakeholders to define expectations.",
            concepts: [L10n.Questions.structuredThinking, L10n.Concepts.communication]
        ),
        InterviewQuestion(
            id: stableID("00000000-0000-0000-0000-000000000005"),
            title: "Leading Remote Teams Effectively",
            category: L10n.Questions.leadership,
            purpose: "Showcase your leadership in a remote environment.",
            tip: "Focus on clear communication and trust-building.",
            answer: "I establish regular check-ins, set clear goals, and encourage open communication across the team.",
            concepts: [L10n.Concepts.communication, L10n.Questions.leadership]
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

