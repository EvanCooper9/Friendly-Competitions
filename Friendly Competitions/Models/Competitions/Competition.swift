import Foundation
import CoreLocation

struct Competition: Codable, Identifiable {
    var id = UUID()
    var name = ""
    var participants = [String]()
    var pendingParticipants = [String]()
    var scoringModel = ScoringModel.percentOfGoals
    var start = Date.now
    var end = Date.now.addingTimeInterval(7.days)

    var isPublic = false
    var location: CLLocationCoordinate2D? = nil
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
}
