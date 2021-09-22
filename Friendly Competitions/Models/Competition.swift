import Foundation

struct Competition: Codable, Identifiable {

    struct Standing: Codable, Equatable, Identifiable {
        var id: String { userId }
        let rank: Int
        let userId: String
        let points: Int
    }

    var id = UUID()
    let name: String
    let participants: [String]
    let pendingParticipants: [String]
    let scoringModel: ScoringModel
    let start: Date
    let end: Date
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
