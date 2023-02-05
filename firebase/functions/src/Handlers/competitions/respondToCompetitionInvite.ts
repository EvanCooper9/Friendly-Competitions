import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Respond to a competition invite
 * @param {string} competitionID The ID of the competition
 * @param {string} callerID The ID of the user responding to the competition
 * @param {boolean} accept Accept or decline the competition invite
 * @return {Promise<void>} A promise that resolve when completed
 */
async function respondToCompetitionInvite(competitionID: string, callerID: string, accept: boolean): Promise<void> {
    const firestore = getFirestore();
    const competition = await firestore.doc(`competitions/${competitionID}`).get().then(doc => new Competition(doc));
    const index = competition.pendingParticipants.indexOf(callerID, 0);
    if (index > -1) competition.pendingParticipants.splice(index, 1);
    if (accept) competition.participants.push(callerID);
    await firestore.doc(`competitions/${competitionID}`)
        .update({
            pendingParticipants: competition.pendingParticipants,
            participants: competition.participants
        });
}

export {
    respondToCompetitionInvite
};
