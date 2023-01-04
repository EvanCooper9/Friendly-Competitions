import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Record current standings in competition history.
 * @param {string} competitionID the id of the competition to record history for
 */
async function recordHistoryManually(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const competitionRef = await firestore.doc(`competitions/${competitionID}`).get();
    const competition = new Competition(competitionRef);
    await competition.recordHistory();
}

export {
    recordHistoryManually
};
