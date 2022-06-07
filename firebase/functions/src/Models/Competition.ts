import * as admin from "firebase-admin";
import * as moment from "moment";
import { ActivitySummary } from "./ActivitySummary";
import { Standing } from "./Standing";
import { Workout } from "./Workout";
import { WorkoutType } from "./WorkoutType";

const dateFormat = "YYYY-MM-DD";

enum ScoringModel {
    percentOfGoals = 0,
    rawNumbers = 1
}

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
    workoutType?: WorkoutType;
    scoringModel?: ScoringModel;

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

        this.workoutType = document.get("workoutType") as WorkoutType;
        this.scoringModel = document.get("scoringModel") as ScoringModel;

        const startDateString: string = document.get("start");
        const endDateString: string = document.get("end");
        this.start = new Date(startDateString);
        this.end = new Date(endDateString);
    }

    /**
     * Updates the points and standings
     */
    async updateStandings(): Promise<void> {
        console.log(`updating standings for competition: ${this.id}`);
        const existingStandings = (await admin.firestore().collection(`competitions/${this.id}/standings`).get()).docs.map(doc => new Standing(doc));
        const standingPromises = this.participants.map(async userId => {
            let totalPoints = 0;
            const workoutType = this.workoutType;
            const scoringModel = this.scoringModel;
            if (workoutType != undefined) {
                const workoutsPromise = await admin.firestore()
                    .collection(`users/${userId}/workouts`)
                    .where("type", "==", workoutType)
                    .get();
                workoutsPromise.docs
                    .map(doc => new Workout(doc))
                    .filter(workout => workout.isIncludedInCompetition(this))
                    .forEach(workout => totalPoints += workout.points);
            } else if (scoringModel != undefined) {
                const activitySummariesPromise = await admin.firestore().collection(`users/${userId}/activitySummaries`).get()
                activitySummariesPromise.docs
                    .map(doc => new ActivitySummary(doc))
                    .filter(activitySummary => activitySummary.isIncludedInCompetition(this))
                    .forEach(activitySummary => {
                        switch (scoringModel) {
                            case ScoringModel.percentOfGoals: {
                                const energy = (activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal) * 100;
                                const exercise = (activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal) * 100;
                                const stand = (activitySummary.appleStandHours / activitySummary.appleStandHoursGoal) * 100;
                                const points = energy + exercise + stand;
                                totalPoints += parseInt(`${points}`);
                            }
                            case ScoringModel.rawNumbers: {
                                const energy = activitySummary.activeEnergyBurned;
                                const exercise = activitySummary.appleExerciseTime;
                                const stand = activitySummary.appleStandHours;
                                const points = energy + exercise + stand;
                                totalPoints += parseInt(`${points}`);
                            }
                        }
                    });
            }

            if (userId.startsWith("Anonymous")) {
                // Dummy standings
                const existingStanding = existingStandings.find(standing => standing.userId == userId);
                const start = moment(this.start);
                const days = moment().diff(start, "days") + 1;
                const todaysPoints = getRandomInt(75, 125);
                if (existingStanding === undefined) {
                    const poits = days * todaysPoints;
                    return Promise.resolve(Standing.new(poits, userId));
                } else if (existingStanding.date != moment().format(dateFormat)) {
                    const poits = existingStanding.points + todaysPoints;
                    return Promise.resolve(Standing.new(poits, userId));
                } else {
                    return Promise.resolve(existingStanding);
                }
            } else {
                return Promise.resolve(Standing.new(totalPoints, userId));
            }
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

/**
 * Returns a random integer between min (inclusive) and max (inclusive).
 * The value is no lower than min (or the next integer greater than min
 * if min isn't an integer) and no greater than max (or the next integer
 * lower than max if max isn't an integer).
 * Using Math.round() will give you a non-uniform distribution!
 * @param {number} min The minimum
 * @param {number} max The maximum
 * @return {number} A random number between the min/max
 */
function getRandomInt(min: number, max: number): number {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

export {
    Competition
};
