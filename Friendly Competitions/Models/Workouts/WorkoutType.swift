import HealthKit

enum WorkoutType: String, CaseIterable, Codable {
    case running
    case walking
}

extension WorkoutType {
    init?(hkWorkoutActivityType: HKWorkoutActivityType) {
        switch hkWorkoutActivityType {
        case .running:
            self = .running
        case .walking:
            self = .walking
        default:
            return nil
        }
    }
}

extension WorkoutType: Identifiable {
    var id: RawValue { rawValue }
}

extension WorkoutType {
    var hkWorkoutActivityType: HKWorkoutActivityType {
        switch self {
        case .running:
            return .running
        case .walking:
            return .walking
        }
    }
}
