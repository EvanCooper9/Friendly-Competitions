import ECKit
import Foundation
import HealthKit

struct Competition: Codable, Equatable, Hashable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var owner: String
    var participants: [String]
    var pendingParticipants: [String]
    var scoringModel: ScoringModel
    @PostDecoded<DateToStartOfDay, Date> var start: Date
    @PostDecoded<DateToEndOfDay, Date> var end: Date
    var repeats: Bool
    var isPublic: Bool
    let banner: String?
}

extension Competition: Stored {
    var databasePath: String { "competitions/\(id)" }
}

extension Competition {
    var started: Bool { start < .now }
    var ended: Bool { end < .now }
    var isActive: Bool { started && !ended }
    var appOwned: Bool { owner == Bundle.main.id }
}

extension Array where Element == Competition {
    var dateInterval: DateInterval? {
        reduce(nil) { existing, competition in
            let dateInterval = DateInterval(start: competition.start, end: competition.end)
            guard let existing else {
                return dateInterval
            }
            return existing.combined(with: dateInterval)
        }
    }
}
