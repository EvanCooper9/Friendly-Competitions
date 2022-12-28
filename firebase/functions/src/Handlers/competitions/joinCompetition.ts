import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Respond to a competition invite
 * @param {string} competitionID The ID of the competition
 * @param {string} callerID The ID of the user responding to the competition
 * @param {boolean} accept Accept or decline the competition invite
 * @return {Promise<void>} A promise that resolve when completed
 */
function joinCompetition(competitionID: string, userID: string): Promise<void> {
    const firestore = getFirestore();

    return firestore.doc(`competitions/${competitionID}`)
        .get()
        .then(doc => new Competition(doc))
        .then(competition => {
            const index = competition.pendingParticipants.indexOf(userID, 0);
            if (index > -1) competition.pendingParticipants.splice(index, 1);
            competition.participants.push(userID);
            const obj = Object.assign({}, competition);
            return firestore.doc(`competitions/${competitionID}`).set(obj);
        })
        .then();
}

export {
    joinCompetition
};
