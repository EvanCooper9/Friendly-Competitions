import { getFirestore } from "firebase-admin/firestore";
import { ActivitySummary } from "../../../Models/ActivitySummary";
import { Competition } from "../../../Models/Competition";

/**
 * Delete all activity summaries that are not in use by active competitions
 * @return {Promise<void>} A promise that resolves when complete
 */
async function cleanupActivitySummaries(): Promise<void> {
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions").get().then(query => query.docs.map(doc => new Competition(doc)));
    const activeCompetitions = competitions.filter(competition => competition.isActive());
    const activitySummaries = await firestore.collectionGroup("activitySummaries").get().then(query => query.docs.map(doc => new ActivitySummary(doc)));

    const batch = firestore.batch();

    activitySummaries
        .filter(activitySummary => {
            const matchingCompetition = activeCompetitions.find(competition => activitySummary.isIncludedInCompetition(competition));
            return matchingCompetition == null || matchingCompetition == undefined; 
        })
        .forEach(activitySummary => {
            const ref = firestore.doc(`users/${activitySummary.userID}/activitySummaries/${activitySummary.id}`);
            batch.delete(ref);
        });

    await batch.commit();
}

export {
    cleanupActivitySummaries
};
