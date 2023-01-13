import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Respond to a competition invite
 * @param {string} competitionID The ID of the competition
 * @param {string} userID The ID of the user leaving the competition
 * @return {Promise<void>} A promise that resolve when completed
 */
function leaveCompetition(competitionID: string, userID: string): Promise<void> {
    const firestore = getFirestore();

    return firestore.doc(`competitions/${competitionID}`)
        .get()
        .then(doc => new Competition(doc))
        .then(competition => {
            const index = competition.participants.indexOf(userID, 0);
            if (index > -1) competition.participants.splice(index, 1);
            return firestore
                .doc(`competitions/${competitionID}`)
                .update({ participants: competition.participants });
        })
        .then(() => {
            return firestore.doc(`competitions/${competitionID}/standings/${userID}`).delete();
        })
        .then();
}

export {
    leaveCompetition
};
