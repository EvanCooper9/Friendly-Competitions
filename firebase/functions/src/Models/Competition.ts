import * as admin from "firebase-admin";
import * as moment from "moment";
import { ActivitySummary } from "./ActivitySummary";
import { RawScoringModel, ScoringModel } from "./ScoringModel";
import { Standing } from "./Standing";
import { Workout } from "./Workout";

const dateFormat = "YYYY-MM-DD";

/**
 * Competition
 */
class Competition {
    id: string;
    name: string;
    start: Date;
    end: Date;
    owner: string;
    participants: string[];
    pendingParticipants: string[];
    repeats: boolean;
    scoringModel: ScoringModel;

    /**
     * Builds a competition from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the competition from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.id;
        this.name = document.get("name");
        this.owner = document.get("owner");
        this.participants = document.get("participants");
        this.pendingParticipants = document.get("pendingParticipants");
        this.repeats = document.get("repeats");

        const legacyScoringModel: number = document.get("scoringModel");
        if (legacyScoringModel == 0 || legacyScoringModel == 1) {
            this.scoringModel = { type: legacyScoringModel };
        } else {
            this.scoringModel = document.get("scoringModel") as ScoringModel;
        }

        const startDateString: string = document.get("start");
        const endDateString: string = document.get("end");
        this.start = new Date(startDateString);
        this.end = new Date(endDateString);
    }

    /**
     * Updates the points and standings
     */
    async updateStandings(): Promise<void> {
        const standingPromises = this.participants.map(async userId => {
            let totalPoints = 0;

            switch (this.scoringModel.type) {
            case RawScoringModel.percentOfGoals: {
                const activitySummaries = await this.activitySummaries(userId);
                activitySummaries.forEach(activitySummary => {
                    const energy = (activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal) * 100;
                    const exercise = (activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal) * 100;
                    const stand = (activitySummary.appleStandHours / activitySummary.appleStandHoursGoal) * 100;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                });
                break;
            }
            case RawScoringModel.rawNumbers: {
                const activitySummaries = await this.activitySummaries(userId);
                activitySummaries.forEach(activitySummary => {
                    const energy = activitySummary.activeEnergyBurned;
                    const exercise = activitySummary.appleExerciseTime;
                    const stand = activitySummary.appleStandHours;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                });
                break;
            }
            case RawScoringModel.workout: {
                const workoutType = this.scoringModel.workoutType;
                const workoutMetrics = this.scoringModel.workoutMetrics;
                if (workoutType != undefined && workoutMetrics != undefined) {
                    const workoutsPromise = await admin.firestore().collection(`users/${userId}/workouts`).get();
                    workoutsPromise.docs
                        .map(doc => new Workout(doc))
                        .filter(workout => workout.type == workoutType && workout.isIncludedInCompetition(this))
                        .forEach(workout => {
                            workoutMetrics.forEach(metric => {
                                totalPoints += workout.points[metric];
                            });
                        });
                }
                break;
            }
            }

            if (isNaN(totalPoints)) {
                totalPoints = 0;
                console.error(`Encountered NaN when setting total points
                    competition: ${this.id}
                    user: ${userId}
                `);
            }
            return Promise.resolve(Standing.new(totalPoints, userId));
        });

        return Promise.all(standingPromises)
            .then(standings => {
                const batch = admin.firestore().batch();
                standings
                    .sort((a, b) => a.points > b.points ? 1 : -1)
                    .reverse()
                    .forEach((standing, index) => {
                        standing.rank = index + 1;
                        const obj = Object.assign({}, standing);
                        const ref = admin.firestore().doc(`competitions/${this.id}/standings/${standing.userId}`);
                        batch.set(ref, obj);
                    });
                return batch.commit();
            })
            .then();
    }

    /**
     * Fetch activity summaries for a user that fall within the bounds of this competition's start & end
     * @param {string} userId The ID of the user to fetch activity summaries for
     * @return {Promise<ActivitySummary[]>} A promise of activity summaries
     */
    async activitySummaries(userId: string): Promise<ActivitySummary[]> {
        const activitySummariesPromise = await admin.firestore().collection(`users/${userId}/activitySummaries`).get();
        return activitySummariesPromise.docs
            .map(doc => new ActivitySummary(doc))
            .filter(activitySummary => activitySummary.isIncludedInCompetition(this));
    }

    /**
     * Update a competition's start & end date if it is repeating
     * @return {Promise<void>} A promise that completes when the update is finished
     */
    async updateRepeatingCompetition(): Promise<void> {
        if (!this.repeats) return Promise.resolve();

        const competitionStart = moment(this.start);
        const competitionEnd = moment(this.end);
        let newStart = competitionStart;
        let newEnd = competitionEnd;
        if (competitionStart.day() == 1 && competitionEnd.day() == competitionEnd.daysInMonth()) {
            newStart = moment(this.start).add(1, "month");
            newEnd = moment(this.start).set("day", newStart.daysInMonth());
        } else {
            const diff = competitionEnd.diff(competitionStart, "days");
            newStart = moment(this.end).add(1, "days");
            newEnd = moment(newStart.format(dateFormat)).add(diff, "days");
        }

        const obj = { start: newStart.format(dateFormat), end: newEnd.format(dateFormat) };
        return admin.firestore().doc(`competitions/${this.id}`)
            .update(obj)
            .then();
    }
}

export {
    Competition
};
