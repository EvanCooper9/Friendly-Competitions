import { DocumentSnapshot } from "firebase-admin/firestore";
import moment = require("moment");
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { Workout } from "../../Models/Workout";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

const dateFormat = "YYYY-MM-DD";

/**
 * Updates all competition standings for the workout that has changed
 * @param {string} userID the ID of the user who owns the workout
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateWorkoutScores(userID: string, before?: DocumentSnapshot, after?: DocumentSnapshot): Promise<void> {
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.all(competitions.map(async competition => {
        if (!competition.isActive()) return;

        const standingDoc = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
        const standingRef = await standingDoc.get();        
        let standing = Standing.new(0, userID);
        if (standingRef.exists) standing = new Standing(standingRef);

        const pointsBreakdown = standing.pointsBreakdown ?? {};
        if (Object.keys(pointsBreakdown).length == 0) {
            const activitySummaries = await competition.activitySummaries(userID);
            activitySummaries.forEach(activitySummary => {
                const id = moment(activitySummary.date).format(dateFormat);
                const points = activitySummary.pointsForScoringModel(competition.scoringModel);
                pointsBreakdown[id] = points;
            });
        } else if (after == null && before != undefined) { // deleted
            const beforeWorkout = new Workout(before);
            if (!beforeWorkout.isIncludedInCompetition(competition)) return;
            pointsBreakdown[before.id] = 0;
        } else if (after != undefined) { // created or updated
            const afterWorkout = new Workout(after);
            if (!afterWorkout.isIncludedInCompetition(competition)) return;
            pointsBreakdown[after.id] = afterWorkout.pointsForScoringModel(competition.scoringModel);
        }

        standing.pointsBreakdown = pointsBreakdown;
        standing.points = 0;
        Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);

        await standingDoc.set(prepareForFirestore(standing));
        await competition.updateStandingRanks();
    }));
}

export {
    updateWorkoutScores
};
