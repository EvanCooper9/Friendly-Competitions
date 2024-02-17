import { DocumentSnapshot } from "firebase-admin/firestore";
import { getFirestore } from "../../Utilities/firestore";
import { Competition } from "../../Models/Competition";
import { StepCount } from "../../Models/StepCount";
import { updateScores } from "./updateScores";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";

/**
 * Updates all competition standings for the step count that has changed
 * @param {string} userID the ID of the user who owns the step count
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateStepCountScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    console.log(`updating step count scores for user ${userID}`);

    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .where("scoringModel.type", "==", 4)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await updateScores(
        userID,
        competitions,
        async (competition) => {
            const pointsBreakdown: StringKeyDictionary<string, number> = {};
            const stepCounts = await competition.stepCounts(userID);
            stepCounts.forEach(stepCount => {
                const points = stepCount.pointsForScoringModel(competition.scoringModel);
                pointsBreakdown[stepCount.id] = points;
            });
            return pointsBreakdown;
        },
        (competition) => {
            if (after.exists) { // created or updated
                const stepCount = new StepCount(after);
                const points = stepCount.pointsForScoringModel(competition.scoringModel);
                return { id: after.id, points: points };
            } else { // deleted
                return { id: before.id, points: 0 };
            }
        }
    );
}

export {
    updateStepCountScores
};
