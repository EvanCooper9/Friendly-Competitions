import HealthKit

extension HKWorkoutActivityType: Codable {}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt { rawValue }
}

extension HKWorkoutActivityType {
    static var supported: [HKWorkoutActivityType] {
        [
            .cycling,
            .running,
            .swimming,
            .walking
        ]
    }
}

extension HKWorkoutActivityType {
    var description: String? {
        switch self {
        case .cycling:
            return "Cycling"
        case .running:
            return "Running"
        case .swimming:
            return "Swimming"
        case .walking:
            return "Walking"
        default:
            return nil
        }
    }
}

extension HKWorkoutActivityType {
    var samples: [(HKQuantityType, HKUnit)] {
        switch self {
        case .cycling:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceCycling)!, .meter())
            ]
        case .running:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, .meter())
            ]
        case .swimming:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceSwimming)!, .meter())
            ]
        case .walking:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, .meter())
            ]
        default:
            return []
        }
    }
}
