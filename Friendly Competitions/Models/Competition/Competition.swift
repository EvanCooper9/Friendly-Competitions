import Foundation

struct Competition: Codable, Identifiable {
    var id = UUID().uuidString
    let name: String

    let owner: String
    var participants: [String]
    var pendingParticipants: [String]

    let scoringModel: ScoringModel

    let start: Date
    let end: Date
    let repeats: Bool

    let isPublic: Bool
    let banner: String?
}

extension Competition: Equatable {
    static func == (lhs: Competition, rhs: Competition) -> Bool {
        lhs.id == rhs.id
    }
}

extension Competition {
    var isActive: Bool { started && !ended }
    var started: Bool { Calendar.current.compare(.now, to: start, toGranularity: .day) != .orderedAscending }
    var ended: Bool { Calendar.current.compare(.now, to: end, toGranularity: .day) == .orderedDescending }
    var appOwned: Bool { owner == Bundle.main.id }
}
