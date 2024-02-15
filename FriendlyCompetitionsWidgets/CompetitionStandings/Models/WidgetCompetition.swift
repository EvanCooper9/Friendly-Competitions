import AppIntents
import Factory
import Foundation
import WidgetKit

public struct WidgetCompetition: Codable {
    public init(id: String, name: String, start: Date, end: Date, standings: [WidgetStanding]) {
        self.id = id
        self.name = name
        self.start = start
        self.end = end
        self.standings = standings
        self.createdOn = .now
    }
    
    public let id: String
    public let name: String
    public let start: Date
    public let end: Date
    public let standings: [WidgetStanding]
    let createdOn: Date
}

extension WidgetCompetition {
    var dateString: String {
        if Date.now.distance(to: start) >= 0 {
            let startString = start.formatted(date: .numeric, time: .omitted)
            return "Starts \(startString)"
        } else {
            let endString = end.formatted(date: .numeric, time: .omitted)
            if Date.now.distance(to: end) >= 0 {
                return "Ends \(endString)"
            }
            return "Ended \(endString)"
        }
    }
}

public extension WidgetCompetition {
    static let placeholder: WidgetCompetition = {
        .init(
            id: UUID().uuidString,
            name: "Placeholder",
            start: .now.addingTimeInterval(-1.days),
            end: .now.addingTimeInterval(1.days),
            standings: .mock
        )
    }()
}
