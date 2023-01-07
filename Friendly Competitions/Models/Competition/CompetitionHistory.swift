import Foundation

struct CompetitionResult: Codable, Identifiable {
    let id: String
    @PostDecoded<DateToMidnight, Date> var start: Date
    @PostDecoded<DateToMidnight, Date> var end: Date
}
