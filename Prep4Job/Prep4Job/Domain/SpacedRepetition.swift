import Foundation

nonisolated enum ReviewItemKind: String, Codable, CaseIterable, Sendable {
    case question
    case concept
}

nonisolated enum ReviewRating: String, Codable, CaseIterable, Sendable, Identifiable {
    case again
    case hard
    case good
    case easy

    var id: Self {
        self
    }
}

nonisolated struct ReviewSchedule: Codable, Equatable, Sendable, Identifiable {
    let contentID: UUID
    let kind: ReviewItemKind
    var dueDate: Date
    var intervalDays: Int
    var repetition: Int
    var easeFactor: Double
    var lastReviewedAt: Date?

    var id: UUID {
        contentID
    }

    init(
        contentID: UUID,
        kind: ReviewItemKind,
        dueDate: Date,
        intervalDays: Int = 0,
        repetition: Int = 0,
        easeFactor: Double = 2.5,
        lastReviewedAt: Date? = nil
    ) {
        self.contentID = contentID
        self.kind = kind
        self.dueDate = dueDate
        self.intervalDays = intervalDays
        self.repetition = repetition
        self.easeFactor = easeFactor
        self.lastReviewedAt = lastReviewedAt
    }
}

/// Algoritmo pequeño basado en SM-2, adecuado para el MVP y fácil de sustituir.
nonisolated struct SpacedRepetitionScheduler: Sendable {
    func initialSchedule(
        contentID: UUID,
        kind: ReviewItemKind,
        now: Date = Date()
    ) -> ReviewSchedule {
        ReviewSchedule(contentID: contentID, kind: kind, dueDate: now)
    }

    func review(
        _ schedule: ReviewSchedule,
        rating: ReviewRating,
        now: Date = Date()
    ) -> ReviewSchedule {
        var updated = schedule
        let nextRepetition = schedule.repetition + 1

        switch rating {
        case .again:
            updated.repetition = 0
            updated.intervalDays = 1
            updated.easeFactor = max(1.3, schedule.easeFactor - 0.2)
        case .hard:
            updated.repetition = schedule.repetition
            updated.intervalDays = max(1, Int((Double(max(schedule.intervalDays, 1)) * 1.2).rounded()))
            updated.easeFactor = max(1.3, schedule.easeFactor - 0.15)
        case .good:
            updated.repetition = nextRepetition
            updated.intervalDays = intervalForGood(repetition: nextRepetition, schedule: schedule)
        case .easy:
            updated.repetition = nextRepetition
            updated.intervalDays = intervalForEasy(repetition: nextRepetition, schedule: schedule)
            updated.easeFactor = min(3.0, schedule.easeFactor + 0.15)
        }

        updated.lastReviewedAt = now
        updated.dueDate = dateByAddingDays(updated.intervalDays, to: now)
        return updated
    }

    private func intervalForGood(repetition: Int, schedule: ReviewSchedule) -> Int {
        switch repetition {
        case 1: 1
        case 2: 3
        default: max(1, Int((Double(max(schedule.intervalDays, 1)) * schedule.easeFactor).rounded()))
        }
    }

    private func intervalForEasy(repetition: Int, schedule: ReviewSchedule) -> Int {
        switch repetition {
        case 1: 2
        case 2: 5
        default: max(1, Int((Double(max(schedule.intervalDays, 1)) * schedule.easeFactor * 1.3).rounded()))
        }
    }

    private func dateByAddingDays(_ days: Int, to date: Date) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: date) ?? date
    }
}
