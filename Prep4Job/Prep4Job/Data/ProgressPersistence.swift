import Foundation

nonisolated struct ProgressSnapshot: Codable, Equatable, Sendable {
    var answeredQuestionIDs: [UUID] = []
    var completedConceptIDs: [UUID] = []
    var savedAnswer = ""
    var streak = 12
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
