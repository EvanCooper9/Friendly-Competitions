import { Competition } from "./Competition";
import { WorkoutType } from "./WorkoutType";

/**
 * Workout
 */
 class Workout {
    type: WorkoutType;
    points: number;
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
}

export {
    Workout
};
