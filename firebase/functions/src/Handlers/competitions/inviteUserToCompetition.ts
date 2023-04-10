import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { sendNotificationsToUser } from "../notifications/notifications";
import { getFirestore } from "../../Utilities/firstore";
import { Constants } from "../../Utilities/Constants";

/**
 * Invites a user to a competition and sends a notification
 * @param {string} competitionID The competition to invite the user to
 * @param {string} callerID The user who is creating the invite
 * @param {string} requesteeID The user who is receiving the invite
 * @return {Promise<void>} A promise that resolves when the user has been invited
 */
async function inviteUserToCompetition(competitionID: string, callerID: string, requesteeID: string): Promise<void> { 
    const firestore = getFirestore();

    const caller = await firestore.doc(`users/${callerID}`).get().then(doc => new User(doc));
    const requestee = await firestore.doc(`users/${requesteeID}`).get().then(doc => new User(doc));
    const competition = await firestore.doc(`competitions/${competitionID}`).get().then(doc => new Competition(doc));

    competition.pendingParticipants.push(requesteeID);

    await firestore.doc(`competitions/${competitionID}`)
        .update({ pendingParticipants: competition.pendingParticipants });
    await sendNotificationsToUser(
        requestee,
        "Friendly Competitions",
        `${caller.name} invited you to a competition`,
        `${Constants.NOTIFICATION_URL}/competition/${competition.id}`
    );
}

export {
    inviteUserToCompetition
};
