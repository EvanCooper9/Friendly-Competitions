extension Competition {
    enum ScoringModel: Equatable, Hashable, Identifiable {
        case percentOfGoals
        case rawNumbers
        case workout(WorkoutType, [WorkoutMetric])

        var id: String { displayName }

        var displayName: String {
            switch self {
            case .percentOfGoals:
                return L10n.Competition.ScoringModel.PercentOfGoals.displayName
            case .rawNumbers:
                return L10n.Competition.ScoringModel.RawNumbers.displayName
            case .workout(let workoutType, _):
                return L10n.Competition.ScoringModel.Workout.displayNameWithType(workoutType.description)
            }
        }

        var description: String {
            switch self {
            case .percentOfGoals:
                return L10n.Competition.ScoringModel.PercentOfGoals.description
            case .rawNumbers:
                return L10n.Competition.ScoringModel.RawNumbers.description
            case .workout(let workoutType, _):
                return L10n.Competition.ScoringModel.Workout.description(workoutType.description)
            }
        }
    }
}

extension Competition.ScoringModel: Codable {

    private struct EncodedModel: Codable {

        enum UnderlyingScoringModel: Int, Codable {
            case percentOfGoals
            case rawNumbers
            case workout
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
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .percentOfGoals:
            try container.encode(EncodedModel(type: .percentOfGoals, workoutType: nil, workoutMetrics: nil))
        case .rawNumbers:
            try container.encode(EncodedModel(type: .rawNumbers, workoutType: nil, workoutMetrics: nil))
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
