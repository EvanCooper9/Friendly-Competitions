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
    var started: Bool { Date.now.compare(start) != .orderedAscending }
    var ended: Bool { Date.now.compare(end) == .orderedDescending }
    var isActive: Bool { started && !ended }
    var appOwned: Bool { owner == Bundle.main.id }
}

extension Array where Element == Competition {
    var dateInterval: DateInterval? {
        return reduce(nil) { dateInterval, competition in
            guard let dateInterval else { return .init(start: competition.start, end: competition.end) }
            return .init(
                start: [dateInterval.start, competition.start].min()!,
                end: [dateInterval.end, competition.end].max()!
            )
        }
    }
}
