import { DocumentSnapshot } from "firebase-admin/firestore";
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";
import { RawScoringModel } from "../../Models/ScoringModel";
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
        .where("scoringModel.type", "in", [0, 1])
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.all(competitions.map(async competition => {
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
            
            standing.pointsBreakdown = pointsBreakdown;
            standing.points = 0;
            Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);
            transaction.set(standingRef, prepareForFirestore(standing));
        });
        
        await competition.updateStandingRanks();
    }));
}

/**
 * 
 * @param {string} userID 
 * @param {DocumentSnapshot} before 
 * @param {DocumentSnapshot} after 
 */
async function updateActivitySummaryScoresNew(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    const firestore = getFirestore();
    const scoringModelTypes = [RawScoringModel.percentOfGoals, RawScoringModel.rawNumbers];
    await Promise.all(scoringModelTypes.map(async scoringModelType => {
        await firestore.runTransaction(async transaction => {
            const ref = firestore.doc(`users/${userID}/scores/${RawScoringModel.toString(scoringModelType)}`);
            const doc = await transaction.get(ref);
            const points = doc.data() as StringKeyDictionary<string, number>;
            
            if (after.exists) {
                const activitySummary = new ActivitySummary(after);
                points[activitySummary.id] = activitySummary.pointsForScoringModel({type: scoringModelType});
            } else {
                points[before.id] = 0;
            }
            
            transaction.update(ref, points);
        });
    }));
}

export {
    updateActivitySummaryScores,
    updateActivitySummaryScoresNew
};
