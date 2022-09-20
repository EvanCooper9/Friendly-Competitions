import HealthKit

enum WorkoutType: String, CaseIterable, Codable, CustomStringConvertible {
    case cycling
    case running
    case swimming
    case walking

    var description: String {
        switch self {
        case .cycling:
            return "Cycling"
        case .running:
            return "Running"
        case .swimming:
            return "Swimming"
        case .walking:
            return "Walking"
        }
    }
}

extension WorkoutType {
    var metrics: [WorkoutMetric] {
        switch self {
        case .cycling:
            return [.distance, .heartRate]
        case .running:
            return [.distance, .heartRate, .steps]
        case .swimming:
            return [.distance, .heartRate]
        case .walking:
            return [.distance, .heartRate, .steps]
        }
    }
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
