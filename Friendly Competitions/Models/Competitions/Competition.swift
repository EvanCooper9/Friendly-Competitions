import Foundation

struct Competition: Codable, Identifiable, Hashable {
    var id = UUID()
    var name = ""
    var participants = [String]()
    var pendingParticipants = [String]()
    var scoringModel = ScoringModel.percentOfGoals
    var start = Date.now
    var end = Date.now.addingTimeInterval(7.days)
}

extension Competition {

    var isActive: Bool {
        started && !ended
    }

    var started: Bool {
        Calendar.current.compare(.now, to: start, toGranularity: .day) != .orderedAscending
    }

    var ended: Bool {
        Calendar.current.compare(.now, to: end, toGranularity: .day) == .orderedDescending
    }
}
