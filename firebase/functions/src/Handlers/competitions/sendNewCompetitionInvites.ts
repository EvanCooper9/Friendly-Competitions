import { getFirestore } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { Constants } from "../../Utilities/Constants";
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
    await Promise.allSettled(competition.pendingParticipants.map(async userID => {
        const user = await firestore.doc(`users/${userID}`).get().then(doc => new User(doc));
        await sendNotificationsToUser(
            user,
            "Friendly Competitions",
            `${owner.name} invited you to a competition`,
            `${Constants.NOTIFICATION_URL}/competition/${competition.id}`
        );
    }));
}

export {
    sendNewCompetitionInvites
};
