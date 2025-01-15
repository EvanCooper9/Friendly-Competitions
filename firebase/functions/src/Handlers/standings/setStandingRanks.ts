import { Standing } from "../../Models/Standing";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";
import { getFirestore } from "../../Utilities/firestore";
import { Competition } from "../../Models/Competition";

/**
 * Update the ranks of standings for a given competition. Assumes points have already been set.
 * @param {Competition} competition The competition for the standings
 * @param {Standing[]} standings The standings to update
 */
export async function setStandingRanks(competition: Competition, standings: Standing[]): Promise<void> {
    if (standings.length == 0) return;
    
    const firestore = getFirestore();
    const batch = firestore.batch();

    standings.sort((a, b) => b.points - a.points);
    const minRank = Math.min(...standings.map(x => x.rank));
    let previousRank = minRank - 1;
    standings.forEach((standing, index, standings) => {
        const isSameAsPrevious = index - 1 >= 0 && standings[index - 1].points == standing.points;
        const isSameAsNext = index + 1 < standings.length && standings[index + 1].points == standing.points;
        const updatedStanding = standing;
        updatedStanding.isTie = isSameAsPrevious || isSameAsNext;
        updatedStanding.rank = isSameAsPrevious ? previousRank : minRank + index;
        previousRank = updatedStanding.rank;

        const ref = firestore.doc(competition.standingsPathForUser(standing.userId));
        batch.set(ref, prepareForFirestore(updatedStanding));
    });

    await batch.commit();
}
