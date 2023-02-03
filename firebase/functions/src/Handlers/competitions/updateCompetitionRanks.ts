import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

/**
 * Updates the ranks of a competition's standings. Assumes points are up to date.
 * @param {string} competitionID 
 * @return {Promise<void>} A promise that resolves when completed
 */
async function updateCompetitionRanks(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const standingsRef = await firestore.collection(`competitions/${competitionID}/standings`).get();
    const standings = standingsRef.docs.map(doc => new Standing(doc));
    const batch = firestore.batch();
    standings
        .sort((a, b) => a.points - b.points)
        .forEach((standing, index) => {
            standing.rank = standings.length - index;
            const ref = firestore.doc(`competitions/${competitionID}/standings/${standing.userId}`);
            batch.set(ref, prepareForFirestore(standing));
        });
    await batch.commit();
}

export {
    updateCompetitionRanks
};
