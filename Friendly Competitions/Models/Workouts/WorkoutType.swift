import HealthKit

enum WorkoutType: String, CaseIterable, Codable {
    case cycling
    case running
    case swimming
    case walking
}

extension WorkoutType {
    init?(hkWorkoutActivityType: HKWorkoutActivityType) {
        switch hkWorkoutActivityType {
        case .cycling:
            self = .cycling
        case .running:
            self = .running
        case .swimming:
            self = .swimming
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
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .swimming:
            return .swimming
        case .walking:
            return .walking
        }
    }
}
