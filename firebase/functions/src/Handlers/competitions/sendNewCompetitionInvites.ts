import { getFirestore } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { sendNotificationsToUser } from "../notifications/notifications";

/**
 * Send invite notifications to all pending participants for a competition
 * @param {string} competitionID The ID of the competition to send notifications for
 * @return {Promise<void>} A promise that resolves when complete
 */
async function sendNewCompetitionInvites(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const competition = await firestore.doc(`competitions/${competitionID}`).get().then(doc => new Competition(doc));
    const owner = await firestore.doc(`users/${competition.owner}`).get().then(doc => new User(doc));

    const users = await firestore.collection("users")
        .where("id", "in", competition.pendingParticipants)
        .get()
        .then(query => query.docs.map(doc => new User(doc)));

    await Promise.all(users.map(async user => {
        await sendNotificationsToUser(
            user,
            "Friendly Competitions",
            `${owner.name} invited you to a competition`,
            `https://friendly-competitions.app/competition/${competition.id}`
        );
    }));
}

export {
    sendNewCompetitionInvites
};
