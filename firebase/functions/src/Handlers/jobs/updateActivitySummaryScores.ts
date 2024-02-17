import { DocumentSnapshot } from "firebase-admin/firestore";
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firestore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

/**
 * Updates all competition standings for the activity summary that has changed
 * @param {string} userID the ID of the user who owns the activity summary
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateActivitySummaryScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    console.log(`updating activity summary scores for user ${userID}`);
    
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .where("scoringModel.type", "in", [0, 1, 3])
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.allSettled(competitions.map(async competition => {
        if (!competition.isActive()) return;

        let previousScore = 0;
        let newScore = 0;

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
                    pointsBreakdown[activitySummary.id] = points;
                });
            } else {
                if (after.exists) { // created or updated
                    const activitySummary = new ActivitySummary(after);
                    pointsBreakdown[activitySummary.id] = activitySummary.pointsForScoringModel(competition.scoringModel);
                } else { // deleted
                    pointsBreakdown[before.id] = 0;
                }
            }

            previousScore = standing.points;
            standing.pointsBreakdown = pointsBreakdown;
            standing.points = 0;
            Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);
            newScore = standing.points;
            transaction.set(standingRef, prepareForFirestore(standing));
        });
        
        const pointRangeLow = Math.min(previousScore, newScore);
        const pointRangeHigh = Math.max(previousScore, newScore);
        await competition.updateStandingRanksBetweenScores(pointRangeLow, pointRangeHigh);
    }));

    if (competitions.length == 0) {
        console.log("Not participating in any competitions");
    }
}

export {
    updateActivitySummaryScores
};
