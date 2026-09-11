import Foundation

nonisolated struct DailyActivity: Codable, Equatable, Sendable, Identifiable {
    let date: Date
    var questionsReviewed: Int
    var conceptsReviewed: Int

    var id: Date {
        date
    }

    var totalReviews: Int {
        questionsReviewed + conceptsReviewed
    }

    init(date: Date, questionsReviewed: Int = 0, conceptsReviewed: Int = 0) {
        self.date = date
        self.questionsReviewed = questionsReviewed
        self.conceptsReviewed = conceptsReviewed
    }
}

nonisolated struct ReminderSettings: Codable, Equatable, Sendable {
    var isEnabled = false
    var hour = 19
    var minute = 0
}
