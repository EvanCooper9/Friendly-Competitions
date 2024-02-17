import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { Workout } from "../../Models/Workout";
import { getFirestore } from "../../Utilities/firestore";
import { updateScores } from "./updateScores";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";

/**
 * Updates all competition standings for the workout that has changed
 * @param {string} userID the ID of the user who owns the workout
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateWorkoutScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    console.log(`updating workout scores for user ${userID}`);

    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .where("scoringModel.type", "==", 2)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await updateScores(
        userID,
        competitions,
        async (competition) => {
            const pointsBreakdown: StringKeyDictionary<string, number> = {};
            const workouts = await competition.workouts(userID);
            workouts.forEach(workout => {
                const points = workout.pointsForScoringModel(competition.scoringModel);
                pointsBreakdown[workout.id] = points;
            });
            return pointsBreakdown;
        },
        (competition) => {
            if (after.exists) { // created or updated
                const workout = new Workout(after);
                const points = workout.pointsForScoringModel(competition.scoringModel);
                return { id: after.id, points: points };
            } else { // deleted
                return { id: before.id, points: 0 };
            }
        }
    );
}

export {
    updateWorkoutScores
};
