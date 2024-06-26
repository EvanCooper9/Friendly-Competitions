import { getFirestore } from "../../Utilities/firestore";

/**
 * Deletes a competition and it's standings
 * @param {string} competitionID the ID of the competition to delete
 */
async function deleteCompetition(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const competitionDoc = firestore.doc(`competitions/${competitionID}`);
    await firestore.recursiveDelete(competitionDoc);
}

export {
    deleteCompetition
};
