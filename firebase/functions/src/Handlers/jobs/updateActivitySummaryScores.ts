import { DocumentSnapshot } from "firebase-admin/firestore";
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firestore";
import { updateScores } from "./updateScores";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";

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

    await updateScores(
        userID,
        competitions,
        async (competition) => {
            const pointsBreakdown: StringKeyDictionary<string, number> = {};
            const activitySummaries = await competition.activitySummaries(userID);
            activitySummaries.forEach(activitySummary => {
                const points = activitySummary.pointsForScoringModel(competition.scoringModel);
                pointsBreakdown[activitySummary.id] = points;
            });
            return pointsBreakdown;
        },
        (competition) => {
            if (after.exists) { // created or updated
                const activitySummary = new ActivitySummary(after);
                const points = activitySummary.pointsForScoringModel(competition.scoringModel);
                return { id: after.id, points: points };
            } else { // deleted
                return { id: before.id, points: 0 };
            }
        }
    );
}

export {
    updateActivitySummaryScores
};
