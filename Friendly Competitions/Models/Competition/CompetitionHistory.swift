import Foundation

struct CompetitionResult: Codable, Identifiable {
    let id: String
    @PostDecoded<DateToStartOfDay, Date> var start: Date
    @PostDecoded<DateToEndOfDay, Date> var end: Date
}
