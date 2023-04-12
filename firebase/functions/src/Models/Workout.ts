import { Competition } from "./Competition";
import { EnumDictionary } from "./Helpers/EnumDictionary";
import { RawScoringModel, ScoringModel } from "./ScoringModel";
import { WorkoutMetric } from "./WorkoutMetric";
import { WorkoutType } from "./WorkoutType";

/**
 * Workout
 */
class Workout {
    id: string;
    type: WorkoutType;
    points: EnumDictionary<WorkoutMetric, number>;
    date: Date;
    userID: string;

    /**
     * Builds a workout record from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the workout record from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.ref.id;
        this.type = document.get("type") as WorkoutType;
        this.points = document.get("points");
        const dateString: string = document.get("date");
        this.date = new Date(dateString);
        this.userID = document.ref.parent.parent?.id ?? "";
    }

    /**
     * Returns true if the workout falls within the competition window
     * @param {Competition} competition the competition to compare against
     * @return {boolean} true if the workout falls within the competition window
     */
    isIncludedInCompetition(competition: Competition): boolean {
        const type = competition.scoringModel.workoutType == this.type;
        const date = this.date >= competition.start && this.date <= competition.end;
        return type && date;
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
            let total = 0;
            scoringModel.workoutMetrics?.forEach(workoutMetric => {
                const points = this.points[workoutMetric];
                if (points == undefined) return;
                total += points;
            });
            return Math.round(total);
        }
        }
    }
}

export {
    Workout
};
