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

    /// Since dates are formatted like yyyy-MM-dd, end would be at 0:00.
    /// We need to set end time to 23:59
    var trueEnd: Date { end.advanced(by: 23.hours + 59.minutes) }

    var started: Bool { Date.now.compare(start) != .orderedAscending }
    var ended: Bool { Date.now.compare(trueEnd) == .orderedDescending }

    var isActive: Bool { started && !ended }

    var appOwned: Bool { owner == Bundle.main.id }
}
