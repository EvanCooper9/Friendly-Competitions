import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import * as moment from "moment";
import { prepareForFirestore } from "../Utilities/prepareForFirestore";
import { ActivitySummary } from "./ActivitySummary";
import { ScoringModel } from "./ScoringModel";
import { Standing } from "./Standing";

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
     * Reset the scores of standings to 0
     */
    async resetStandings(): Promise<void> { 
        const standingsRef = await admin.firestore().collection(`competitions/${this.id}/standings`).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));
        const batch = admin.firestore().batch();
        standings.forEach(standing => {
            standing.points = 0;
            const ref = admin.firestore().doc(`competitions/${this.id}/standings/${standing.userId}`);
            batch.set(ref, prepareForFirestore(standing));
        });
        await batch.commit();
    }

    /**
     * Updates the points and standings
     */
    async updateStandingRanks(): Promise<void> {
        const standingsRef = await admin.firestore().collection(`competitions/${this.id}/standings`).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));
        const batch = admin.firestore().batch();
        standings
            .sort((a, b) => a.points - b.points)
            .forEach((standing, index) => {
                standing.rank = standings.length - index;
                const ref = admin.firestore().doc(`competitions/${this.id}/standings/${standing.userId}`);
                batch.set(ref, prepareForFirestore(standing));
            });
        await batch.commit();
    }

    /**
     * Update a competition's start & end date if it is repeating
     * @return {Promise<void>} A promise that completes when the update is finished
     */
    async updateRepeatingCompetition(): Promise<void> {
        if (!this.repeats) return;

        const competitionStart = moment(this.start);
        const competitionEnd = moment(this.end);
        let newStart = competitionStart;
        let newEnd = competitionEnd;
        if (competitionStart.day() == 1 && competitionEnd.day() == competitionEnd.daysInMonth()) {
            newStart = moment(this.end).add(1, "days");
            newEnd = moment(this.end).add(1, "days").set("day", newStart.daysInMonth());
        } else {
            const diff = competitionEnd.diff(competitionStart, "days");
            newStart = moment(this.end).add(1, "days");
            newEnd = moment(newStart.format(dateFormat)).add(diff, "days");
        }

        const obj = { start: newStart.format(dateFormat), end: newEnd.format(dateFormat) };
        await admin.firestore().doc(`competitions/${this.id}`).update(obj);
    }

    /**
     * Record current standings in results
     */
    async recordResults(): Promise<void> {
        const firestore = getFirestore();
        const standingsRef = await firestore.collection(`competitions/${this.id}/standings`).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));

        const batch = firestore.batch();
        
        const end = moment(this.end).format(dateFormat);
        const resultsRef = firestore.doc(`competitions/${this.id}/results/${end}`);
        const resultsObj = {
            id: end, 
            start: moment(this.start).format(dateFormat), 
            end: end
        };
        batch.set(resultsRef, resultsObj);

        standings.forEach(standing => {
            const ref = firestore.doc(`competitions/${this.id}/results/${end}/standings/${standing.userId}`);
            batch.set(ref, prepareForFirestore(standing));
        });
        await batch.commit();
    }

    /**
     * Return a bool that indicates if the competition is currently active
     * @return {boolean} true if the competition is currently active
     */
    isActive(): boolean {
        const competitionStart = moment(this.start);
        const competitionEnd = moment(this.end).set("hour", 23).set("minute", 59);
        const now = moment();
        return now >= competitionStart && now <= competitionEnd;
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
}

export {
    Competition
};
