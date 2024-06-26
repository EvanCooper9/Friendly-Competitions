import Foundation

struct Workout: Codable, Equatable, Hashable {
    let type: WorkoutType
    let date: Date
    let points: [WorkoutMetric: Int]
}

extension Workout: Identifiable {
    var id: String { "\(DateFormatter.dateDashed.string(from: date))_\(type)" }
}
