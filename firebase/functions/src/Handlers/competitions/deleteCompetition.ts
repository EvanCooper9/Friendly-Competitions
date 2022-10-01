import { getFirestore } from "../../Utilities/firstore";

/**
 * Deletes a competition and it's standings
 * @param {string} competitionID the ID of the competition to delete
 */
async function deleteCompetition(competitionID: string) {
    const firestore = getFirestore();
    const competitionDoc = firestore.doc(`competitions/${competitionID}`);
    await firestore.recursiveDelete(competitionDoc);
}

export {
    deleteCompetition
};
