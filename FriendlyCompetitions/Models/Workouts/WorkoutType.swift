import HealthKit

enum WorkoutType: String, CaseIterable, Codable, CustomStringConvertible, Hashable {
    case cycling
    case running
    case swimming
    case walking

    var description: String {
        switch self {
        case .cycling:
            return L10n.WorkoutType.Cycling.description
        case .running:
            return L10n.WorkoutType.Running.description
        case .swimming:
            return L10n.WorkoutType.Swimming.description
        case .walking:
            return L10n.WorkoutType.Walking.description
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

extension WorkoutType {

    private var distancePermissionType: HealthKitPermissionType {
        switch self {
        case .cycling:
            return .distanceCycling
        case .swimming:
            return .distanceSwimming
        case .running, .walking:
            return .distanceWalkingRunning
        }
    }

    func requiredPermissions(for metrics: [WorkoutMetric]) -> [Permission] {
        metrics.map { metric in
            switch metric {
            case .distance:
                return .health(distancePermissionType)
            case .heartRate:
                return .health(.heartRate)
            case .steps:
                return .health(.stepCount)
            }
        }.appending(.health(.workoutType))
    }
}
