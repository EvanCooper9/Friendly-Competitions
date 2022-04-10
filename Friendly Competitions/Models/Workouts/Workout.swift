import Foundation
import HealthKit

struct Workout: Codable {
    var id = UUID().uuidString
    let type: HKWorkoutActivityType
    let date: Date
    let points: Int
}
