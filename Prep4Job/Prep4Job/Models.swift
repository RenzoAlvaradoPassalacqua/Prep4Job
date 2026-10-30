import Foundation

struct InterviewQuestion: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let purpose: String
    let tip: String
    let answer: String
    let concepts: [String]
    let requiresPremium: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        purpose: String,
        tip: String,
        answer: String,
        concepts: [String],
        requiresPremium: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.purpose = purpose
        self.tip = tip
        self.answer = answer
        self.concepts = concepts
        self.requiresPremium = requiresPremium
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, category, purpose, tip, answer, concepts, requiresPremium
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.category = try container.decode(String.self, forKey: .category)
        self.purpose = try container.decode(String.self, forKey: .purpose)
        self.tip = try container.decode(String.self, forKey: .tip)
        self.answer = try container.decode(String.self, forKey: .answer)
        self.concepts = try container.decode([String].self, forKey: .concepts)
        self.requiresPremium = try container.decodeIfPresent(Bool.self, forKey: .requiresPremium) ?? false
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(purpose, forKey: .purpose)
        try container.encode(tip, forKey: .tip)
        try container.encode(answer, forKey: .answer)
        try container.encode(concepts, forKey: .concepts)
        try container.encode(requiresPremium, forKey: .requiresPremium)
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
