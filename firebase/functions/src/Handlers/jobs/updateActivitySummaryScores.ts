import { DocumentSnapshot } from "firebase-admin/firestore";
import moment = require("moment");
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

/**
 * Updates all competition standings for the activity summary that has changed
 * @param {string} userID the ID of the user who owns the activity summary
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateActivitySummaryScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    const firestore = getFirestore();

    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.all(competitions.map(async competition => {
        if (!competition.isActive()) return;

        const date = new Date(after.id);
        if (date < competition.start || date > competition.end) return;

        await firestore.runTransaction(async transaction => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standingDoc = await transaction.get(standingRef);
            let standing = Standing.new(0, userID);
            if (standingDoc.exists) standing = new Standing(standingDoc);
    
            const pointsBreakdown = standing.pointsBreakdown ?? {};
            if (Object.keys(pointsBreakdown).length == 0) {
                const activitySummaries = await competition.activitySummaries(userID);
                activitySummaries.forEach(activitySummary => {
                    const points = activitySummary.pointsForScoringModel(competition.scoringModel);
                    pointsBreakdown[after.id] = points;
                });
            } else {
                if (after.exists) { // created or updated
                    const activitySummary = new ActivitySummary(after);
                    pointsBreakdown[after.id] = activitySummary.pointsForScoringModel(competition.scoringModel);
                } else { // deleted
                    pointsBreakdown[before.id] = 0;
                }
            }
            
            standing.pointsBreakdown = pointsBreakdown;
            standing.points = 0;
            Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);
            transaction.set(standingRef, prepareForFirestore(standing));
        });
        
        await competition.updateStandingRanks();
    }));
}

export {
    updateActivitySummaryScores
};
