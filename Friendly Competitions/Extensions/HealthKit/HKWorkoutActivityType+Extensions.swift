import HealthKit

extension HKWorkoutActivityType: Codable {}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt { rawValue }
}

extension HKWorkoutActivityType {
    static var supported: [HKWorkoutActivityType] {
        [
            .running,
            .walking
        ]
    }
}

extension HKWorkoutActivityType {
    var description: String? {
        switch self {
        case .running:
            return "Running"
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
        case .running:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, .meter())
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
