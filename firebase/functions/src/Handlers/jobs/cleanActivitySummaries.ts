import { getFirestore } from "firebase-admin/firestore";
import moment = require("moment");
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";

/**
 * Delete all activity summaries that are not in use by active competitions
 * @return {Promise<void>} A promise that resolves when complete
 */
async function cleanActivitySummaries(): Promise<void> {
    const firestore = getFirestore();
    const users = await firestore.collection("users").get().then(query => query.docs.map(doc => new User(doc)));
    const competitions = await firestore.collection("competitions").get().then(query => query.docs.map(doc => new Competition(doc)));

    const batch = firestore.batch();
    await Promise.all(users.map(async user => {
        const participatingCompetitions = competitions.filter(competition => competition.participants.includes(user.id));
        const activitySummaries = await firestore.collection(`users/${user.id}/activitySummaries`).get()
            .then(query => query.docs.map(doc => new ActivitySummary(doc)));
        
        activitySummaries
            .filter(activitySummary => {
                const matchingCompetition = participatingCompetitions.find(competition => activitySummary.isIncludedInCompetition(competition));
                return matchingCompetition == null || matchingCompetition == undefined;
            })
            .forEach(activitySummary => {
                const id = moment(activitySummary.date).format("YYYY-MM-DD");
                const ref = firestore.doc(`users/${user.id}/activitySummaries/${id}`);
                batch.delete(ref);
            });
    }));
    await batch.commit();
}

export {
    cleanActivitySummaries
};
