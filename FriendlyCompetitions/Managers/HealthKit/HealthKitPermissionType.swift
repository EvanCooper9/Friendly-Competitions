import HealthKit

enum HealthKitPermissionType: String, CaseIterable, Codable {
    case activeEnergy
    case appleExerciseTime
    case appleMoveTime
    case appleStandTime
    case appleStandHour
    case activitySummaryType

    // workout metrics
    case workoutType
    case distanceCycling
    case heartRate
    case distanceWalkingRunning
    case stepCount
    case distanceSwimming

    var objectType: HKObjectType {
        switch self {
        case .activeEnergy:
            return HKQuantityType(.activeEnergyBurned)
        case .appleExerciseTime:
            return HKQuantityType(.appleExerciseTime)
        case .appleMoveTime:
            return HKQuantityType(.appleMoveTime)
        case .appleStandTime:
            return HKQuantityType(.appleStandTime)
        case .appleStandHour:
            return HKCategoryType(.appleStandHour)
        case .activitySummaryType:
            return .activitySummaryType()
        case .workoutType:
            return .workoutType()
        case .distanceCycling:
            return HKQuantityType(.distanceCycling)
        case .heartRate:
            return HKQuantityType(.heartRate)
        case .distanceWalkingRunning:
            return HKQuantityType(.distanceWalkingRunning)
        case .stepCount:
            return HKQuantityType(.stepCount)
        case .distanceSwimming:
            return HKQuantityType(.distanceSwimming)
        }
    }
}
