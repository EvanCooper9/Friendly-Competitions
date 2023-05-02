import { Standing } from "../../Models/Standing";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";
import { getFirestore } from "../../Utilities/firstore";
import { Competition } from "../../Models/Competition";

/**
 * Update the ranks of standings for a given competition
 * @param {Competition} competition The competition for the standings
 * @param {Standing[]} standings The standings to update
 */
async function calculateStandingsRanks(competition: Competition, standings: Standing[]): Promise<void> {
    const firestore = getFirestore();
    const batch = firestore.batch();

    const sortedStandings = standings
        .sort((a, b) => a.points - b.points)
        .reverse();

    let currentRank = 1;
    sortedStandings
        .forEach((standing, index, standings) => {
            const updatedStanding = standing;
            
            if (index == 0) {
                console.log(JSON.stringify(standings));
            }

            const isSameAsPrevious = index - 1 >= 0 && standings[index - 1].points == updatedStanding.points;
            const isSameAsNext = index + 1 < standings.length && standings[index + 1].points == updatedStanding.points;
            
            updatedStanding.isTie = isSameAsPrevious || isSameAsNext;

            if (isSameAsPrevious && !isSameAsNext) { // tied with previous only
                // don't increase rank
            } else if (isSameAsPrevious && isSameAsNext) { // tied with previous and next
                // don't increase rank
            } else if (!isSameAsPrevious && isSameAsNext) { // tied with next only
                currentRank = index + 1;
            } else if (!isSameAsPrevious && !isSameAsNext) { // not tied at all
                currentRank = index + 1;
            }
            updatedStanding.rank = currentRank;

            // Don't update firestore with the same data.
            // if (updatedStanding.rank == standing.rank && updatedStanding.isTie == standing.isTie) return;

            const ref = firestore.doc(competition.standingsPathForUser(standing.userId));
            batch.set(ref, prepareForFirestore(updatedStanding));
        });

    await batch.commit();
}

export {
    calculateStandingsRanks
};
