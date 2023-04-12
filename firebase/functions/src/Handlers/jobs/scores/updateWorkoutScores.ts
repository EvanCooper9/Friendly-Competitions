import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../../Models/Competition";
import { Standing } from "../../../Models/Standing";
import { Workout } from "../../../Models/Workout";
import { getFirestore } from "../../../Utilities/firstore";
import { prepareForFirestore } from "../../../Utilities/prepareForFirestore";

/**
 * Updates all competition standings for the workout that has changed
 * @param {string} userID the ID of the user who owns the workout
 * @param {DocumentSnapshot} before the document before the change
 * @param {DocumentSnapshot} after the document after the change
 */
async function updateWorkoutScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    const firestore = getFirestore();

    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .where("scoringModel.type", "==", 2)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.allSettled(competitions.map(async competition => {
        if (!competition.isActive()) return;

        await firestore.runTransaction(async transaction => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standingDoc = await transaction.get(standingRef);
            let standing = Standing.new(0, userID);
            if (standingDoc.exists) standing = new Standing(standingDoc);

            const pointsBreakdown = standing.pointsBreakdown ?? {};
            if (Object.keys(pointsBreakdown).length == 0) {
                const workouts = await competition.workouts(userID);
                workouts.forEach(workout => {
                    const points = workout.pointsForScoringModel(competition.scoringModel);
                    pointsBreakdown[workout.id] = points;
                });
            } else {
                if (after.exists) { // created or updated
                    const workout = new Workout(after);
                    pointsBreakdown[workout.id] = workout.pointsForScoringModel(competition.scoringModel);
                } else {
                    pointsBreakdown[before.id] = 0;
                }
            }

            standing.pointsBreakdown = pointsBreakdown;
            await transaction.set(standingRef, prepareForFirestore(standing));
        });

        await competition.updateOldestStandingUpdate();
    }));
}

export {
    updateWorkoutScores
};
