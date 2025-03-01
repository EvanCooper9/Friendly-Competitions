import { Competition } from "./Competition";
import { RawScoringModel, ScoringModel } from "./ScoringModel";

/**
 * Activity summary
 */
class ActivitySummary {
    id: string;
    activeEnergyBurned: number;
    activeEnergyBurnedGoal: number;
    appleExerciseTime: number;
    appleExerciseTimeGoal: number;
    appleStandHours: number;
    appleStandHoursGoal: number;
    date: Date;
    userID: string;

    /**
     * Builds an activity summary from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the activity summary from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.ref.id;
        this.activeEnergyBurned = document.get("activeEnergyBurned");
        this.activeEnergyBurnedGoal = document.get("activeEnergyBurnedGoal");
        this.appleExerciseTime = document.get("appleExerciseTime");
        this.appleExerciseTimeGoal = document.get("appleExerciseTimeGoal");
        this.appleStandHours = document.get("appleStandHours");
        this.appleStandHoursGoal = document.get("appleStandHoursGoal");

        const dateString: string = document.get("date");
        this.date = new Date(dateString);

        this.userID = document.get("userID");
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
    pointsForScoringModel(scoringModel: ScoringModel): number {
        switch (scoringModel.type) {
        case RawScoringModel.percentOfGoals: {
            const energy = (this.activeEnergyBurned / this.activeEnergyBurnedGoal) * 100;
            const exercise = (this.appleExerciseTime / this.appleExerciseTimeGoal) * 100;
            const stand = (this.appleStandHours / this.appleStandHoursGoal) * 100;
            return Math.round(energy + exercise + stand);
        }
        case RawScoringModel.rawNumbers: {
            return Math.round(this.activeEnergyBurned + this.appleExerciseTime + this.appleStandHours);
        }
        case RawScoringModel.workout: {
            return 0;
        }
        case RawScoringModel.activityRingCloseCount: {
            const energy = this.activeEnergyBurned >= this.activeEnergyBurnedGoal ? 1 : 0;
            const exercise = this.appleExerciseTime >= this.appleExerciseTimeGoal ? 1 : 0;
            const stand = this.appleStandHours >= this.appleStandHoursGoal ? 1 : 0;
            return energy + exercise + stand;
        }
        case RawScoringModel.stepCount: {
            return 0;
        }
        }
    }
}

export {
    ActivitySummary
};
