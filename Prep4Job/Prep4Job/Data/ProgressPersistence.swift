import Foundation
import Supabase

nonisolated struct ProgressSnapshot: Codable, Equatable, Sendable {
    var answeredQuestionIDs: [UUID] = []
    var completedConceptIDs: [UUID] = []
    var savedAnswer = ""
    var savedAnswers: [UUID: String] = [:]
    var streak = 12
    var reviewSchedules: [ReviewSchedule] = []
    var dailyActivity: [DailyActivity] = []
    var reminderSettings = ReminderSettings()
    var lastStudyDate: Date?
    var totalStudySessions = 0

    init(
        answeredQuestionIDs: [UUID] = [],
        completedConceptIDs: [UUID] = [],
        savedAnswer: String = "",
        savedAnswers: [UUID: String] = [:],
        streak: Int = 12,
        reviewSchedules: [ReviewSchedule] = [],
        dailyActivity: [DailyActivity] = [],
        reminderSettings: ReminderSettings = ReminderSettings(),
        lastStudyDate: Date? = nil,
        totalStudySessions: Int = 0
    ) {
        self.answeredQuestionIDs = answeredQuestionIDs
        self.completedConceptIDs = completedConceptIDs
        self.savedAnswer = savedAnswer
        self.savedAnswers = savedAnswers
        self.streak = streak
        self.reviewSchedules = reviewSchedules
        self.dailyActivity = dailyActivity
        self.reminderSettings = reminderSettings
        self.lastStudyDate = lastStudyDate
        self.totalStudySessions = totalStudySessions
    }

    private enum CodingKeys: String, CodingKey {
        case answeredQuestionIDs
        case completedConceptIDs
        case savedAnswer
        case savedAnswers
        case streak
        case reviewSchedules
        case dailyActivity
        case reminderSettings
        case lastStudyDate
        case totalStudySessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answeredQuestionIDs = try container.decodeIfPresent([UUID].self, forKey: .answeredQuestionIDs) ?? []
        completedConceptIDs = try container.decodeIfPresent([UUID].self, forKey: .completedConceptIDs) ?? []
        savedAnswer = try container.decodeIfPresent(String.self, forKey: .savedAnswer) ?? ""
        savedAnswers = try container.decodeIfPresent([UUID: String].self, forKey: .savedAnswers) ?? [:]
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 12
        reviewSchedules = try container.decodeIfPresent([ReviewSchedule].self, forKey: .reviewSchedules) ?? []
        dailyActivity = try container.decodeIfPresent([DailyActivity].self, forKey: .dailyActivity) ?? []
        reminderSettings = try container.decodeIfPresent(ReminderSettings.self, forKey: .reminderSettings)
            ?? ReminderSettings()
        lastStudyDate = try container.decodeIfPresent(Date.self, forKey: .lastStudyDate)
        totalStudySessions = try container.decodeIfPresent(Int.self, forKey: .totalStudySessions) ?? 0
    }
}

nonisolated protocol ProgressPersistence: Sendable {
    func load() async -> ProgressSnapshot
    func save(_ snapshot: ProgressSnapshot) async
}

actor FileProgressPersistence: ProgressPersistence {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() async -> ProgressSnapshot {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(ProgressSnapshot.self, from: data)
        } catch {
            return ProgressSnapshot()
        }
    }

    func save(_ snapshot: ProgressSnapshot) async {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // La persistencia es una mejora de durabilidad; no debe bloquear la UI.
        }
    }
}

enum ProgressPersistenceFactory {
    static func makeDefault() -> FileProgressPersistence {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = directory.appendingPathComponent("prep4job-progress.json")
        return FileProgressPersistence(fileURL: fileURL)
    }
}

actor SupabaseProgressSync {
    static let shared = SupabaseProgressSync()
    private let client: SupabaseClient?

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientFactory.make()
    }

    func save(_ snapshot: ProgressSnapshot, contentID: UUID, kind: ReviewItemKind) async {
        guard let client, let userID = client.auth.currentUser?.id else { return }
        let row = SupabaseProgressRow(
            userID: userID,
            userContentID: contentID,
            kind: kind.rawValue,
            answered: kind == .question
                ? snapshot.answeredQuestionIDs.contains(contentID)
                : snapshot.completedConceptIDs.contains(contentID),
            savedAnswer: kind == .question ? snapshot.savedAnswers[contentID] ?? "" : ""
        )
        do {
            try await client
                .from("progress_items")
                .upsert([row], onConflict: "user_id,content_id,content_kind", returning: .minimal)
                .execute()
        } catch {
            Observability.capture(error, context: ["feature": "progress_sync"])
        }
    }
}

nonisolated private struct SupabaseProgressRow: Encodable {
    let userID: UUID
    let contentID: UUID
    let contentKind: String
    let answered: Bool
    let savedAnswer: String

    init(userID: UUID, userContentID: UUID, kind: String, answered: Bool, savedAnswer: String) {
        self.userID = userID
        contentID = userContentID
        contentKind = kind
        self.answered = answered
        self.savedAnswer = savedAnswer
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case contentID = "content_id"
        case contentKind = "content_kind"
        case answered
        case savedAnswer = "saved_answer"
    }
}
