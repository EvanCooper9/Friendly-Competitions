import ECKit
import Foundation
import HealthKit

struct Competition: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var owner: String
    var participants: [String]
    var pendingParticipants: [String]
    var scoringModel: ScoringModel
    @PostDecoded<DateToMidnight, Date> var start: Date
    @PostDecoded<DateToMidnight, Date> var end: Date
    var repeats: Bool
    var isPublic: Bool
    let banner: String?
}

extension Competition {
    var started: Bool { Date.now.compare(start) != .orderedAscending }
    var ended: Bool { Date.now.compare(end) == .orderedDescending }
    var isActive: Bool { started && !ended }
    var appOwned: Bool { owner == Bundle.main.id }
}

extension Array where Element == Competition {
    var dateInterval: DateInterval {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let now = Calendar.current.date(from: components) ?? .now
        let yesterday = now.addingTimeInterval(-1.days)
        let tomorrow = now.addingTimeInterval(1.days)
        return reduce(DateInterval(start: yesterday, end: tomorrow)) { dateInterval, competition in
            .init(
                start: [dateInterval.start, competition.start, yesterday].min() ?? yesterday,
                end: [dateInterval.end, competition.end, tomorrow].max() ?? tomorrow
            )
        }
    }
}
