import { Competition } from "./Competition";
import { RawScoringModel, ScoringModel } from "./ScoringModel";

/**
 * StepCount
 */
class StepCount {
    id: string;
    count: number;
    date: Date;

    /**
     * Builds a standing record from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the standing record from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.ref.id;
        this.count = document.get("count");
        
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
                return 0;
            }
            case RawScoringModel.activityRingCloseCount: {
                return 0;
            }
            case RawScoringModel.stepCount: {
                return this.count;
            }
            }
    }
}

export {
    StepCount
};
