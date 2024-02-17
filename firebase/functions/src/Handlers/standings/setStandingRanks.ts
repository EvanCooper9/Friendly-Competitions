import { Standing } from "../../Models/Standing";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";
import { getFirestore } from "../../Utilities/firestore";
import { Competition } from "../../Models/Competition";

/**
 * Update the ranks of standings for a given competition
 * @param {Competition} competition The competition for the standings
 * @param {Standing[]} standings The standings to update
 */
async function setStandingRanks(competition: Competition, standings: Standing[]): Promise<void> {
    if (standings.length == 0) return;
    
    const firestore = getFirestore();
    const batch = firestore.batch();

    const sortedStandings = standings
        .sort((a, b) => a.points - b.points)
        .reverse();

    let currentRank = standings[0].rank;

    sortedStandings.forEach((standing, index, standings) => {
        console.log(`updating standing ${standing.userId} with rank ${standing.rank}`);
        const updatedStanding = standing;

        const isSameAsPrevious = index - 1 >= 0 && standings[index - 1].points == updatedStanding.points;
        const isSameAsNext = index + 1 < standings.length && standings[index + 1].points == updatedStanding.points;
        
        updatedStanding.isTie = isSameAsPrevious || isSameAsNext;

        if (!isSameAsPrevious) {
            currentRank = index + 1;
        }

        updatedStanding.rank = currentRank;

        if (updatedStanding != standing) {
            // Don't update firestore with the same data.
            const ref = firestore.doc(competition.standingsPathForUser(standing.userId));
            batch.set(ref, prepareForFirestore(updatedStanding)); 
        }
    });

    await batch.commit();
}

export {
    setStandingRanks
};
