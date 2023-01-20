import { Competition } from "./Competition";
import { RawScoringModel, ScoringModel } from "./ScoringModel";

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

    /**
     * Calculate how many points are earned based on a scoring model
     * @param {ScoringModel} scoringModel the scoring model for a given competition
     * @return {number} the amount of points
     */
    pointsFor(scoringModel: ScoringModel): number {
        switch (scoringModel.type) {
            case RawScoringModel.percentOfGoals: {
                const energy = (this.activeEnergyBurned / this.activeEnergyBurnedGoal) * 100;
                const exercise = (this.appleExerciseTime / this.appleExerciseTimeGoal) * 100;
                const stand = (this.appleStandHours / this.appleStandHoursGoal) * 100;
                return energy + exercise + stand;
            }
            case RawScoringModel.rawNumbers: {
                return this.activeEnergyBurned + this.appleExerciseTime + this.appleStandHours;
            }
            case RawScoringModel.workout: {
                return 0
            }
        }

    }
}

export {
    ActivitySummary
};
