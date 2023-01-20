import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { sendNotificationsToUser } from "../notifications/notifications";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Invites a user to a competition and sends a notification
 * @param {string} competitionID The competition to invite the user to
 * @param {string} callerID The user who is creating the invite
 * @param {string} requesteeID The user who is receiving the invite
 * @return {Promise<void>} A promise that resolves when the user has been invited
 */
function inviteUserToCompetition(competitionID: string, callerID: string, requesteeID: string): Promise<void> { 
    const firestore = getFirestore();

    const caller = firestore.doc(`users/${callerID}`)
        .get()
        .then(doc => new User(doc));

    const requestee = firestore.doc(`users/${requesteeID}`)
        .get()
        .then(doc => new User(doc));

    const competition = firestore.doc(`competitions/${competitionID}`)
        .get()
        .then(doc => new Competition(doc));

    return Promise.all([competition, caller, requestee])
        .then(result => {
            const competition = result[0];
            const caller = result[1];
            const requestee = result[2];

            competition.pendingParticipants.push(requesteeID);

            const pendingParticipants = competition.pendingParticipants;
            pendingParticipants.push(requesteeID);

            return firestore.doc(`competitions/${competitionID}`)
                .update({ pendingParticipants: pendingParticipants })
                .then(() => {
                    return sendNotificationsToUser(
                        requestee,
                        "Friendly Competitions",
                        `${caller.name} invited you to a competition`,
                        `https://friendly-competitions.app/competition/${competition.id}`
                    );
                });
        });
}

export {
    inviteUserToCompetition
};
