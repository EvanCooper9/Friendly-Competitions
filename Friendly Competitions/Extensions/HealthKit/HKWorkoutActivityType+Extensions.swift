import HealthKit

extension HKWorkoutActivityType {
    var samples: [(HKQuantityType, HKUnit)] {
        switch self {
        case .cycling:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceCycling)!, .meter()),
                (HKObjectType.quantityType(forIdentifier: .heartRate)!,  .init(from: "count/min")),
            ]
        case .running:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, .meter()),
                (HKObjectType.quantityType(forIdentifier: .heartRate)!, .init(from: "count/min")),
                (HKObjectType.quantityType(forIdentifier: .stepCount)!, .count())
            ]
        case .swimming:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceSwimming)!, .meter()),
                (HKObjectType.quantityType(forIdentifier: .heartRate)!, .init(from: "count/min")),
            ]
        case .walking:
            return [
                (HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, .meter()),
                (HKObjectType.quantityType(forIdentifier: .heartRate)!, .init(from: "count/min")),
                (HKObjectType.quantityType(forIdentifier: .stepCount)!, .count())
            ]
        default:
            return []
        }
    }
}
