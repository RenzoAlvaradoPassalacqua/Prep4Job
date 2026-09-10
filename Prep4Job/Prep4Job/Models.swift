import Foundation

struct InterviewQuestion: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let purpose: String
    let tip: String
    let answer: String
    let concepts: [String]

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        purpose: String,
        tip: String,
        answer: String,
        concepts: [String]
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.purpose = purpose
        self.tip = tip
        self.answer = answer
        self.concepts = concepts
    }
}

struct LearningStep: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let detail: String

    init(id: UUID = UUID(), title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

struct LearningConcept: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let explanation: String
    let steps: [LearningStep]
    let color: ConceptColor

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        explanation: String,
        steps: [LearningStep],
        color: ConceptColor
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.explanation = explanation
        self.steps = steps
        self.color = color
    }

    static func == (lhs: LearningConcept, rhs: LearningConcept) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ConceptColor: Hashable, Codable, Sendable {
    case indigo, mint, amber, violet
}
