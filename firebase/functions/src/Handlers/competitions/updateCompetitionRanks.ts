import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Updates the ranks of a competition's standings. Assumes points are up to date.
 * @param {string} competitionID 
 * @return {Promise<void>} A promise that resolves when completed
 */
async function updateCompetitionRanks(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const competitionRef = await firestore.doc(`competitions/${competitionID}`).get();
    const competition = new Competition(competitionRef);
    await competition.updateStandingRanks();
}

export {
    updateCompetitionRanks
};
