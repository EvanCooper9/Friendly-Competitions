import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Respond to a competition invite
 * @param {string} competitionID The ID of the competition
 * @param {string} userID The ID of the user leaving the competition
 * @return {Promise<void>} A promise that resolve when completed
 */
async function leaveCompetition(competitionID: string, userID: string): Promise<void> {
    const firestore = getFirestore();
    const competition = await firestore.doc(`competitions/${competitionID}`).get().then(doc => new Competition(doc));
    const index = competition.participants.indexOf(userID, 0);
    if (index > -1) competition.participants.splice(index, 1);
    await firestore.doc(`competitions/${competitionID}`).update({ participants: competition.participants });
    await firestore.doc(`competitions/${competitionID}/standings/${userID}`).delete();
    await competition.updateStandingRanks();
}

export {
    leaveCompetition
};
