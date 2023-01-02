import { getFirestore } from "firebase-admin/firestore";
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";

/**
 * Delete all activity summaries that are not in use by active competitions
 * @return {Promise<void>} A promise that resolves when complete
 */
async function cleanActivitySummaries(): Promise<void> {
    const firestore = getFirestore();
    const users = (await firestore.collection("users").get()).docs.map(doc => new User(doc));
    const competitions = (await firestore.collection("competitions").get()).docs.map(doc => new Competition(doc));
    const cleanUsers = users.map(async user => {
        const participatingCompetitions = competitions.filter(competition => competition.participants.includes(user.id));
        const activitySummariesToDelete = (await firestore.collection(`users/${user.id}/activitySummaries`).get())
            .docs
            .filter(doc => {
                const activitySummary = new ActivitySummary(doc);
                const matchingCompetition = participatingCompetitions.find(competition => activitySummary.isIncludedInCompetition(competition));
                return matchingCompetition == null || matchingCompetition == undefined;
            })
            .map(doc => firestore.doc(`users/${user.id}/activitySummaries/${doc.id}`).delete());

        return Promise.all(activitySummariesToDelete);
    });

    return Promise.all(cleanUsers).then();
}

export {
    cleanActivitySummaries
};
