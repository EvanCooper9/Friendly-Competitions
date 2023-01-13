import { getFirestore } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { sendNotificationsToUser } from "../../notifications";

/**
 * Send invite notifications to all pending participants for a competition
 * @param {string} competitionID The ID of the competition to send notifications for
 * @return {Promise<void>} A promise that resolves when complete
 */
function sendNewCompetitionInvites(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    return firestore.doc(`competitions/${competitionID}`)
        .get()
        .then(doc => new Competition(doc))
        .then(competition => {
            return firestore.doc(`users/${competition.owner}`)
                .get()
                .then(doc => new User(doc))
                .then(user => {
                    return { 
                        competition: competition, 
                        user: user 
                    };
                });
        })
        .then(result => {
            const competition = result.competition;
            const owner = result.user;
            const notifications = competition.pendingParticipants.map(pendingParticipant => {
                return firestore.doc(`users/${pendingParticipant}`)
                    .get()
                    .then(doc => new User(doc))
                    .then(pendingParticipant => {
                        return sendNotificationsToUser(
                            pendingParticipant,
                            "Friendly Competitions",
                            `${owner.name} invited you to a competition`,
                            `https://friendly-competitions.app/competition/${competition.id}`
                        );
                    });
            });
            return Promise.all(notifications).then();
        });
}

export {
    sendNewCompetitionInvites
};
