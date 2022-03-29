import * as admin from "firebase-admin";
import * as moment from "moment";
import { ActivitySummary } from "./ActivitySummary";
import { Standing } from "./Standing";

const dateFormat = "YYYY-MM-DD";
const firestore = admin.firestore();

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
        this.scoringModel = document.get("scoringModel");

        const startDateString: string = document.get("start");
        const endDateString: string = document.get("end");
        this.start = new Date(startDateString);
        this.end = new Date(endDateString);
    }

    /**
     * Updates the points and standings
     */
    async updateStandings() {
        const standings: Standing[] = [];
        this.participants.forEach(async userId => {
            let totalPoints = 0;
            const activitySummaries = (await firestore.collection(`users/${userId}/activitySummaries`).get()).docs.map(doc => new ActivitySummary(doc));
            activitySummaries.forEach(activitySummary => {
                if (!activitySummary.isIncludedInCompetition(this)) return;
                if (this.scoringModel == 0) {
                    const energy = (activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal) * 100;
                    const exercise = (activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal) * 100;
                    const stand = (activitySummary.appleStandHours / activitySummary.appleStandHoursGoal) * 100;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                } else if (this.scoringModel == 1) {
                    const energy = activitySummary.activeEnergyBurned;
                    const exercise = activitySummary.appleExerciseTime;
                    const stand = activitySummary.appleStandHours;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                }
            });
            standings.push(Standing.new(totalPoints, userId));
        });
        
        const batch = firestore.batch();
        firestore.collection(`competitions/${this.id}/standings`)
            .listDocuments()
            .then(docs => docs.forEach(doc => batch.delete(doc)));
        batch.commit();

        standings
            .sort((a, b) => a.points > b.points ? 1 : -1)
            .reverse()
            .forEach(async (standing, index) => {
                standing.rank = index + 1;
                const obj = Object.assign({}, standing);
                await firestore
                    .doc(`competitions/${this.id}/standings/${standing.userId}`)
                    .set(obj);
            });
    }

    /**
     * Update a competition's start & end date if it is repeating
     * @param {Competition} competition The competition to update
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
