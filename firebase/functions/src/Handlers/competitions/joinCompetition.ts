import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Respond to a competition invite
 * @param {string} competitionID The ID of the competition
 * @param {string} userID The ID of the user joining the competition
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
            return firestore.doc(`competitions/${competitionID}`)
                .update({ 
                    participants: competition.participants,
                    pendingParticipants: competition.pendingParticipants
                });
        })
        .then();
}

export {
    joinCompetition
};
