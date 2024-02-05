import HealthKit

enum WorkoutMetric: String, CaseIterable, Codable, Hashable {
    case distance
    case heartRate
    case steps
}

extension WorkoutMetric {
    init?(from identifier: String) {
        switch HKQuantityTypeIdentifier(rawValue: identifier) {
        case .distanceCycling, .distanceWalkingRunning, .distanceSwimming:
            self = .distance
        case .heartRate:
            self = .heartRate
        case .stepCount:
            self = .steps
        default:
            return nil
        }
    }
}

extension WorkoutMetric: CodingKey, CodingKeyRepresentable {

    var codingKey: CodingKey { self }

    init?<T>(codingKey: T) where T : CodingKey {
        guard let metric = WorkoutMetric(rawValue: codingKey.stringValue) else { return nil }
        self = metric
    }
}

extension WorkoutMetric: CustomStringConvertible {
    var description: String {
        switch self {
        case .distance:
            return L10n.WorkoutMetric.Distance.description
        case .heartRate:
            return L10n.WorkoutMetric.HeartRate.description
        case .steps:
            return L10n.WorkoutMetric.Steps.description
        }
    }
}

extension WorkoutMetric: Identifiable {
    var id: String { rawValue }
}

extension WorkoutMetric {

    func permission(for workoutType: WorkoutType) -> HealthKitPermissionType? {
        switch (self, workoutType) {
        case (.distance, .cycling):
            return .distanceCycling
        case (.distance, .running), (.distance, .walking):
            return .distanceWalkingRunning
        case (.distance, .swimming):
            return .distanceSwimming
        case (.heartRate, _):
            return .heartRate
        case (.steps, .running), (.steps, .walking):
            return .stepCount
        default:
            return nil
        }
    }

    func sample(for workoutType: WorkoutType) -> HKQuantityType? {
        switch (self, workoutType) {
        case (.distance, .cycling):
            return HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        case (.distance, .swimming):
            return HKObjectType.quantityType(forIdentifier: .distanceSwimming)!
        case (.distance, .running), (.distance, .walking):
            return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        case (.steps, .running), (.steps, .walking):
            return HKObjectType.quantityType(forIdentifier: .stepCount)!
        case (.heartRate, _):
            return HKObjectType.quantityType(forIdentifier: .heartRate)!
        default:
            return nil
        }
    }

    var unit: HKUnit {
        switch self {
        case .distance:
            return .meter()
        case .heartRate:
            return .init(from: "count/min")
        case .steps:
            return .count()
        }
    }
}
