import Foundation

struct StepCount: Codable, Hashable, Identifiable {
    var id: String { date.encodedToString(with: .dateDashed) }

    let count: Int
    let date: Date
}
