import { Competition } from "./Competition";

/**
 * Activity summary
 */
class ActivitySummary {
    activeEnergyBurned: number;
    activeEnergyBurnedGoal: number;
    appleExerciseTime: number;
    appleExerciseTimeGoal: number;
    appleStandHours: number;
    appleStandHoursGoal: number;
    date: Date;

    /**
     * Builds an activity summary from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the activity summary from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.activeEnergyBurned = document.get("activeEnergyBurned");
        this.activeEnergyBurnedGoal = document.get("activeEnergyBurnedGoal");
        this.appleExerciseTime = document.get("appleExerciseTime");
        this.appleExerciseTimeGoal = document.get("appleExerciseTimeGoal");
        this.appleStandHours = document.get("appleStandHours");
        this.appleStandHoursGoal = document.get("appleStandHoursGoal");

        const dateString: string = document.get("date");
        this.date = new Date(dateString);
    }

    /**
     * Returns true if the activity summary falls within the competition window
     * @param {Competition} competition the competition to compare against
     * @return {boolean} true if the activity summary falls within the competition window
     */
    isIncludedInCompetition(competition: Competition): boolean {
        return this.date >= competition.start && this.date <= competition.end;
    }
}

export {
    ActivitySummary
};
