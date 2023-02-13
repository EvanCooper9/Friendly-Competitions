import { WorkoutMetric } from "./WorkoutMetric";
import { WorkoutType } from "./WorkoutType";

enum RawScoringModel {
    percentOfGoals = 0,
    rawNumbers = 1,
    workout = 2
}

namespace RawScoringModel {
    export function toString(scoringModel: RawScoringModel): string {
        switch (scoringModel) {
        case RawScoringModel.percentOfGoals:
            return "percentOfGoals";
        case RawScoringModel.rawNumbers:
            return "rawNumbers";
        case RawScoringModel.workout:
            return "workout"
        }
    }
}

interface ScoringModel {
    type: RawScoringModel;
    workoutType?: WorkoutType;
    workoutMetrics?: [WorkoutMetric];
}

export { 
    RawScoringModel,
    ScoringModel
};
