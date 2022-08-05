import HealthKit

enum WorkoutMetric: String, CaseIterable, Codable {
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
            return "Distance"
        case .heartRate:
            return "Heart rate"
        case .steps:
            return "Steps"
        }
    }
}

extension WorkoutMetric: Identifiable {
    var id: String { rawValue }
}

extension WorkoutMetric {
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
