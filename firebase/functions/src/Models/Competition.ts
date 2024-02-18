import * as moment from "moment";
import { sendNotificationsToUser } from "../Handlers/notifications/notifications";
import { Constants } from "../Utilities/Constants";
import { prepareForFirestore } from "../Utilities/prepareForFirestore";
import { ActivitySummary } from "./ActivitySummary";
import { ScoringModel } from "./ScoringModel";
import { Standing } from "./Standing";
import { User } from "./User";
import { Workout } from "./Workout";
import { setStandingRanks } from "../Handlers/standings/setStandingRanks";
import { getFirestore } from "../Utilities/firestore";
import { StepCount } from "./StepCount";

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

    private path: string;
    private standingsPath: string;
    private resultsPath: string; 

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

        this.path = `competitions/${this.id}`;
        this.standingsPath = `${this.path}/standings`;
        this.resultsPath = `${this.path}/results`;
    }

    /**
     * Reset the scores of standings to 0
     */
    async resetStandings(): Promise<void> { 
        const firestore = getFirestore();
        const standings = await firestore.collection(this.standingsPath)
            .get()
            .then(query => query.docs.map(doc => new Standing(doc)));
        
        standings.map(standing => {
            standing.points = 0;
            standing.pointsBreakdown = {};
            return standing;
        });
        
        await setStandingRanks(this, standings);
    }

    /**
     * Updates the points and standings
     */
    async updateStandingRanks(): Promise<void> {
        const firestore = getFirestore();
        const standings = await firestore.collection(this.standingsPath)
            .get()
            .then(query => query.docs.map(doc => new Standing(doc)));
        await setStandingRanks(this, standings);
    }

    /**
     * Updates the ranks for standings that are between a given point range
     * @param {number} lowScore the low of the point rage
     * @param {number} highScore the high of the point range
     */
    async updateStandingRanksBetweenScores(lowScore: number, highScore: number): Promise<void> {
        const firestore = getFirestore();

        const standings = await firestore.collection(this.standingsPath)
            .where("points", ">=", lowScore)
            .where("points", "<=", highScore)
            .get()
            .then(query => query.docs.map(doc => new Standing(doc)));

        const ranks = standings.map(x => x.rank);
        const minRank = Math.min(...ranks);
        const maxRank = Math.max(...ranks);

        if (standings.length <= 1) return; // no need to update
        
        console.log(`updating standings (${standings.length}) for competition ${this.id} between scores ${lowScore} - ${highScore}, between ranks ${minRank} - ${maxRank}`);
        await setStandingRanks(this, standings);
    }

    /**
     * Update a competition's start & end date if it is repeating
     * @return {Promise<void>} A promise that completes when the update is finished
     */
    async updateRepeatingCompetition(): Promise<void> {
        if (!this.repeats) return;
        const firestore = getFirestore();
        const competitionStart = moment(this.start);
        const competitionEnd = moment(this.end);
        let newStart = competitionStart;
        let newEnd = competitionEnd;
        if (competitionStart.day() == 1 && competitionEnd.day() == competitionEnd.daysInMonth()) {
            newStart = moment(this.end).add(1, "days");
            newEnd = newStart.endOf("month");
        } else {
            const diff = competitionEnd.diff(competitionStart, "days");
            newStart = moment(this.end).add(1, "days");
            newEnd = moment(newStart.format(dateFormat)).add(diff, "days");
        }

        const obj = { start: newStart.format(dateFormat), end: newEnd.format(dateFormat) };
        await firestore.doc(`competitions/${this.id}`).update(obj);
    }

    /**
     * Kicks and notifies users who scored 0 points in a competition.
     */
    async kickInactiveUsers(): Promise<void> {
        if (this.owner != "com.evancooper.FriendlyCompetitions") return;

        const firestore = getFirestore();
        const standingsRef = await firestore.collection(this.standingsPath).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));

        const batch = firestore.batch();

        const inactiveUserIds: string[] = [];
        const activeUserIds: string[] = [];
        
        standings.forEach(standing => {
            if (standing.points == 0) {
                inactiveUserIds.push(standing.userId);
                const standingDoc = firestore.doc(this.standingsPathForUser(standing.userId));
                batch.delete(standingDoc);
            } else {
                activeUserIds.push(standing.userId);
            }
        });

        this.participants = activeUserIds;

        if (inactiveUserIds.length == 0) return;

        const obj = { participants: activeUserIds };
        batch.update(firestore.doc(this.path), obj);
        await batch.commit();

        const inactiveUsers = await firestore.collection("users")
            .where("id", "in", inactiveUserIds)
            .get()
            .then(query => query.docs.map(doc => new User(doc)));

        await Promise.allSettled(inactiveUsers.map(async user => {
            await sendNotificationsToUser(
                user,
                `You have been kicked from ${this.name}`,
                "No points were scored. Tap to rejoin.",
                `${Constants.NOTIFICATION_URL}/competition/${this.id}`
            );
        }));
    }

    /**
     * Record current standings in results
     */
    async recordResults(): Promise<void> {
        const firestore = getFirestore();
        const standingsRef = await firestore.collection(this.standingsPath).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));

        const batch = firestore.batch();
        
        const end = moment(this.end).format(dateFormat);
        const resultsRef = firestore.doc(`${this.resultsPath}/${end}`);
        const resultsObj = {
            id: end, 
            start: moment(this.start).format(dateFormat), 
            end: end,
            participants: this.participants
        };
        batch.set(resultsRef, resultsObj);

        standings.forEach(standing => {
            const ref = firestore.doc(`${this.resultsPath}/${end}/standings/${standing.userId}`);
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
     * @param {string} userID The ID of the user to fetch activity summaries for
     * @return {Promise<ActivitySummary[]>} A promise of activity summaries
     */
    async activitySummaries(userID: string): Promise<ActivitySummary[]> {
        return await getFirestore().collection(`users/${userID}/activitySummaries`)
            .where("date", ">=", moment(this.start).format(dateFormat))
            .get()
            .then(query => query.docs.map(doc => new ActivitySummary(doc)))
            .then(activitySummaries => activitySummaries.filter(x => x.isIncludedInCompetition(this)));
    }

    /**
     * Fetch activity summaries for a user that fall within the bounds of this competition's start & end
     * @param {string} userID The ID of the user to fetch activity summaries for
     * @return {Promise<StepCount[]>} A promise of step counts
     */
    async stepCounts(userID: string): Promise<StepCount[]> {
        return await getFirestore().collection(`users/${userID}/steps`)
            .where("date", ">=", moment(this.start).format(dateFormat))
            .get()
            .then(query => query.docs.map(doc => new StepCount(doc)))
            .then(activitySummaries => activitySummaries.filter(x => x.isIncludedInCompetition(this)));
    }

    /**
     * Fetch workouts for a user that fall within the bounds of this competition's start & end
     * @param {string} userID The ID of the user to fetch workouts for
     * @return {Promise<ActivitySummary[]>} A promise of workouts
     */
    async workouts(userID: string): Promise<Workout[]> {
        const workoutType = this.scoringModel.workoutType;
        if (workoutType == null) return Promise.resolve([]);
        return await getFirestore().collection(`users/${userID}/workouts`)
            .where("type", "==", workoutType)
            .where("date", ">=", moment(this.start).format(dateFormat))
            .get()
            .then(query => query.docs.map(doc => new Workout(doc)))
            .then(workouts => workouts.filter(x => x.isIncludedInCompetition(this)));
    }

    /**
     * Get the document path for the standings of a given user
     * @param {string} userID the ID of the user
     * @return {string} The document path
     */
    standingsPathForUser(userID: string): string {
        return `${this.standingsPath}/${userID}`;
    }
}

export {
    Competition
};
