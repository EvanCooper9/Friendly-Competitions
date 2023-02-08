import { getFirestore } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { Workout } from "../../Models/Workout";

/**
 * Delete all activity summaries that are not in use by active competitions
 * @return {Promise<void>} A promise that resolves when complete
 */
async function cleanupWorkouts(): Promise<void> {
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions").get().then(query => query.docs.map(doc => new Competition(doc)));
    const activeCompetitions = competitions.filter(competition => competition.isActive());
    const workouts = await firestore.collectionGroup("workouts").get().then(query => query.docs.map(doc => new Workout(doc)));

    const batch = firestore.batch();

    workouts
        .filter(workout => {
            const matchingCompetition = activeCompetitions.find(competition => workout.isIncludedInCompetition(competition));
            return matchingCompetition == null || matchingCompetition == undefined; 
        })
        .forEach(workout => {
            const ref = firestore.doc(`users/${workout.userID}/workouts/${workout.id}`);
            batch.delete(ref);
        });
        
    await batch.commit();
}

export {
    cleanupWorkouts
};
