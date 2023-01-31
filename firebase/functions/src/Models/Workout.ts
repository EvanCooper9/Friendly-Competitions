import { Competition } from "./Competition";
import { EnumDictionary } from "./Helpers/EnumDictionary";
import { RawScoringModel, ScoringModel } from "./ScoringModel";
import { WorkoutMetric } from "./WorkoutMetric";
import { WorkoutType } from "./WorkoutType";

/**
 * Workout
 */
class Workout {
    type: WorkoutType;
    points: EnumDictionary<WorkoutMetric, number>;
    date: Date;

    /**
     * Builds a workout record from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the workout record from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.type = document.get("type") as WorkoutType;
        this.points = document.get("points");
        const dateString: string = document.get("date");
        this.date = new Date(dateString);
    }

    /**
     * Returns true if the workout falls within the competition window
     * @param {Competition} competition the competition to compare against
     * @return {boolean} true if the workout falls within the competition window
     */
    isIncludedInCompetition(competition: Competition): boolean {
        return this.date >= competition.start && this.date <= competition.end;
    }

    /**
     * Calculate how many points are earned based on metrics from a scoring model
     * @param {WorkoutMetric[]} workoutMetrics The metrics to filter points by
     * @return {number} Total points based on metrics
     */
    pointsForMetrics(workoutMetrics: WorkoutMetric[]): number {
        const total = 0;
        workoutMetrics.forEach(workoutMetric => this.points[workoutMetric]);
        return total;
    }

    /**
     * Calculate how many points are earned based on a scoring model
     * @param {ScoringModel} scoringModel the scoring model for a given competition
     * @return {number} the amount of points
     */
    pointsForScoringModel(scoringModel: ScoringModel): number {
        switch (scoringModel.type) {
        case RawScoringModel.percentOfGoals: {
            return 0;
        }
        case RawScoringModel.rawNumbers: {
            return 0;
        }
        case RawScoringModel.workout: {
            const total = 0;
            scoringModel.workoutMetrics?.forEach(workoutMetric => this.points[workoutMetric]);
            return total;
        }
        }
    }
}

export {
    Workout
};
