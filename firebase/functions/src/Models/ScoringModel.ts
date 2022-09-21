import { WorkoutMetric } from "./WorkoutMetric";
import { WorkoutType } from "./WorkoutType";

enum RawScoringModel {
    percentOfGoals = 0,
    rawNumbers = 1,
    workout = 2
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
