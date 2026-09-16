import Foundation

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

    func save(_ snapshot: ProgressSnapshot, contentID: UUID, kind: ReviewItemKind) async {
        guard let token = await AuthSessionCoordinator.shared.accessToken(),
              let userID = Self.userID(from: token),
              let url = URL(string: "https://acwfqycsiauktidsvgci.supabase.co/rest/v1/progress_items") else { return }
        let row = ProgressRow(
            userID: userID,
            userContentID: contentID,
            kind: kind.rawValue,
            answered: kind == .question
                ? snapshot.answeredQuestionIDs.contains(contentID)
                : snapshot.completedConceptIDs.contains(contentID),
            savedAnswer: kind == .question ? snapshot.savedAnswers[contentID] ?? "" : ""
        )
        guard let body = try? JSONEncoder().encode([row]) else { return }
        var request = URLRequest(url: url.appending(queryItems: [URLQueryItem(name: "on_conflict", value: "user_id,content_id,content_kind")]))
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("sb_publishable_hf8it8jHmBjK7kAqYZUQSw_eoI74gjO", forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func userID(from token: String) -> UUID? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var encoded = String(parts[1]).replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
        guard let data = Data(base64Encoded: encoded),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subject = payload["sub"] as? String else { return nil }
        return UUID(uuidString: subject)
    }

    private struct ProgressRow: Encodable {
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
}
