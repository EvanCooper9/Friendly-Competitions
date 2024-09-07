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

    var url: URL {
        switch self {
        case .activeEnergy:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierActiveEnergyBurned")!
        case .appleExerciseTime:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierAppleExerciseTime")!
        case .appleMoveTime:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierAppleMoveTime")!
        case .appleStandTime:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierAppleStandTime")!
        case .appleStandHour:
            URL(string: "x-apple-health://SampleType/HKCategoryTypeIdentifierAppleStandHour")!
        case .activitySummaryType:
            .health
        case .workoutType:
            .health
        case .distanceCycling:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierDistanceCycling")!
        case .heartRate:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierHeartRate")!
        case .distanceWalkingRunning:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierDistanceWalkingRunning")!
        case .stepCount:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierStepCount")!
        case .distanceSwimming:
            URL(string: "x-apple-health://SampleType/HKQuantityTypeIdentifierDistanceSwimming")!
        }
    }
}
