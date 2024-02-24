extension Competition {
    enum ScoringModel: Equatable, Hashable, Identifiable {
        case activityRingCloseCount
        case percentOfGoals
        case rawNumbers
        case stepCount
        case workout(WorkoutType, [WorkoutMetric])

        var id: String { displayName }

        var displayName: String {
            switch self {
            case .activityRingCloseCount:
                return L10n.Competition.ScoringModel.ActivityRingCloseCount.displayName
            case .percentOfGoals:
                return L10n.Competition.ScoringModel.PercentOfGoals.displayName
            case .rawNumbers:
                return L10n.Competition.ScoringModel.RawNumbers.displayName
            case .stepCount:
                return L10n.Competition.ScoringModel.Steps.displayName
            case .workout(let workoutType, _):
                return L10n.Competition.ScoringModel.Workout.displayNameWithType(workoutType.description)
            }
        }

        var description: String {
            switch self {
            case .activityRingCloseCount:
                return L10n.Competition.ScoringModel.ActivityRingCloseCount.description
            case .percentOfGoals:
                return L10n.Competition.ScoringModel.PercentOfGoals.description
            case .rawNumbers:
                return L10n.Competition.ScoringModel.RawNumbers.description
            case .stepCount:
                return L10n.Competition.ScoringModel.Steps.description
            case .workout(let workoutType, _):
                return L10n.Competition.ScoringModel.Workout.descriptionWithType(workoutType.description)
            }
        }
    }
}

extension Competition.ScoringModel: Codable {

    private struct EncodedModel: Codable {

        enum UnderlyingScoringModel: Int, Codable {
            case percentOfGoals = 0
            case rawNumbers = 1
            case workout = 2
            case activityRingCloseCount = 3
            case stepCount = 4
        }

        let type: UnderlyingScoringModel
        let workoutType: WorkoutType?
        let workoutMetrics: [WorkoutMetric]?
    }

    init(from decoder: Decoder) throws {
        if let legacy = Self.decodeLegacy(from: decoder) {
            self = legacy
            return
        }

        let container = try decoder.singleValueContainer()
        let encodedModel = try container.decode(EncodedModel.self)

        switch encodedModel.type {
        case .percentOfGoals:
            self = .percentOfGoals
        case .rawNumbers:
            self = .rawNumbers
        case .workout:
            guard let workoutType = encodedModel.workoutType, let workoutMetrics = encodedModel.workoutMetrics else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Could not determine type from underlying model: \(encodedModel)"
                )
            }
            self = .workout(workoutType, workoutMetrics)
        case .activityRingCloseCount:
            self = .activityRingCloseCount
        case .stepCount:
            self = .stepCount
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .activityRingCloseCount:
            try container.encode(EncodedModel(type: .activityRingCloseCount, workoutType: nil, workoutMetrics: nil))
        case .percentOfGoals:
            try container.encode(EncodedModel(type: .percentOfGoals, workoutType: nil, workoutMetrics: nil))
        case .rawNumbers:
            try container.encode(EncodedModel(type: .rawNumbers, workoutType: nil, workoutMetrics: nil))
        case .stepCount:
            try container.encode(EncodedModel(type: .stepCount, workoutType: nil, workoutMetrics: nil))
        case .workout(let workoutType, let workoutMetrics):
            try container.encode(EncodedModel(type: .workout, workoutType: workoutType, workoutMetrics: workoutMetrics))
        }
    }

    private static func decodeLegacy(from decoder: Decoder) -> Self? {
        guard let container = try? decoder.singleValueContainer(), let int = try? container.decode(Int.self) else { return nil }
        if int == 0 {
            return .percentOfGoals
        } else if int == 1 {
            return .rawNumbers
        }
        return nil
    }
}

extension Competition.ScoringModel {
    var requiredPermissions: [Permission] {

        let healthKitPermissions: [Permission] = {
            switch self {
            case .activityRingCloseCount, .percentOfGoals, .rawNumbers:
                return [
                    .health(.activitySummaryType),
                    .health(.activeEnergy),
                    .health(.appleExerciseTime),
                    .health(.appleMoveTime),
                    .health(.appleStandTime),
                    .health(.appleStandHour)
                ]
            case .stepCount:
                return [.health(.stepCount)]
            case let .workout(workoutType, metrics):
                return workoutType.requiredPermissions(for: metrics)
            }
        }()

        return healthKitPermissions + [.notifications]
    }
}
