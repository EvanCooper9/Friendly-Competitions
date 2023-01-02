import Foundation

struct CompetitionHistory: Codable, Identifiable {
    let id: String
    @PostDecoded<DateToMidnight, Date> var start: Date
    @PostDecoded<DateToMidnight, Date> var end: Date
}
