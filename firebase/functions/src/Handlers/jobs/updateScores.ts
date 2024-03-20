import { Competition } from "../../Models/Competition";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firestore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

/* eslint-disable valid-jsdoc */
/**
 * Generic function for updating the scores of given competitions.
 * @param {string} userID the ID of the user who has new scores
 * @param {Competition[]} competitions competitions to update new scores for
 * @param generateEntirePointsBreakdown function to return all points for the competition's range
 * @param generateSinglePointsBreakdown function to return a single day's points in a competition.
 */
async function updateScores(
    userID: string, 
    competitions: Competition[], 
    generateEntirePointsBreakdown: (competition: Competition) => Promise<StringKeyDictionary<string, number>>,
    generateSinglePointsBreakdown: (competition: Competition) => { id: string, points: number }
): Promise<void> {
    const firestore = getFirestore();

    await Promise.allSettled(competitions.map(async competition => {
        const endTime = competition.end.getTime();
        const gracePeriodMS = 43200000;
        if (endTime + gracePeriodMS > Date.now()) return;

        let previousScore = 0;
        let newScore = 0;

        await firestore.runTransaction(async transaction => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standingDoc = await transaction.get(standingRef);
            let standing = Standing.new(0, userID);
            if (standingDoc.exists) standing = new Standing(standingDoc);
    
            let pointsBreakdown = standing.pointsBreakdown ?? {};
            if (Object.keys(pointsBreakdown).length == 0) {
                pointsBreakdown = await generateEntirePointsBreakdown(competition);
            } else {
                const singlePointsBreakdown = generateSinglePointsBreakdown(competition);
                pointsBreakdown[singlePointsBreakdown.id] = singlePointsBreakdown.points;
            }
            
            previousScore = standing.points;
            standing.pointsBreakdown = pointsBreakdown;
            standing.points = 0;
            Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);
            newScore = standing.points;
            transaction.set(standingRef, prepareForFirestore(standing));
        });

        const pointRangeLow = Math.min(previousScore, newScore);
        const pointRangeHigh = Math.max(previousScore, newScore);
        await competition.updateStandingRanksBetweenScores(pointRangeLow, pointRangeHigh);
    }));

    if (competitions.length == 0) {
        console.log("Not participating in any competitions");
    }
}

export { 
    updateScores 
};
