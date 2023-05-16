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
    const firestore = getFirestore();
    const batch = firestore.batch();

    const sortedStandings = standings
        .sort((a, b) => a.points - b.points)
        .reverse();

    let currentRank = 1;
    sortedStandings.forEach((standing, index, standings) => {
        const updatedStanding = standing;

        const isSameAsPrevious = index - 1 >= 0 && standings[index - 1].points == updatedStanding.points;
        const isSameAsNext = index + 1 < standings.length && standings[index + 1].points == updatedStanding.points;
        
        updatedStanding.isTie = isSameAsPrevious || isSameAsNext;

        if (!isSameAsPrevious) {
            currentRank = index + 1;
        }

        updatedStanding.rank = currentRank;

        // Don't update firestore with the same data.
        // if (updatedStanding.points == standing.points && 
        //     updatedStanding.rank == standing.rank && 
        //     updatedStanding.isTie == standing.isTie) return;

        const ref = firestore.doc(competition.standingsPathForUser(standing.userId));
        batch.set(ref, prepareForFirestore(updatedStanding)); 
    });

    await batch.commit();
}

export {
    setStandingRanks
};
