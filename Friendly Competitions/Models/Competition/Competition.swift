import Foundation

struct Competition: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var owner: String
    var participants: [String]
    var pendingParticipants: [String]
    var scoringModel: ScoringModel
    var start: Date
    var end: Date
    var repeats: Bool
    var isPublic: Bool
    var banner: String?
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
