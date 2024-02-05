import Foundation

struct CompetitionResult: Codable, Hashable, Identifiable {
    let id: String
    @PostDecoded<DateToStartOfDay, Date> var start: Date
    @PostDecoded<DateToEndOfDay, Date> var end: Date
    let participants: [User.ID]

    var dateInterval: DateInterval { .init(start: start, end: end) }
}
