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
        const endTime = competition.end.getTime() + 86400000; // end date @ midnight
        const gracePeriodMS = 43200000; // 12 hours in milliseconds
        if (endTime + gracePeriodMS < Date.now()) {
            console.log(`competition ${competition.id} has ended, not updating scores`);
            console.log(`competition end time: ${new Date(endTime).toISOString()}, current time: ${new Date().toISOString()}`);
            console.log(`grace period end time: ${new Date(endTime + gracePeriodMS).toISOString()}`);
            console.log(`current time: ${new Date().toISOString()}`);
            return; // competition has ended, no need to update scores
        }

        console.log(`updating scores for competition ${competition.id} and user ${userID}`);
        
        let previousScore = 0;
        let newScore = 0;

        await firestore.runTransaction(async transaction => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standingDoc = await transaction.get(standingRef);
            let standing = Standing.new(0, userID);
            if (standingDoc.exists) standing = new Standing(standingDoc);

            let pointsBreakdown = standing.pointsBreakdown ?? {};
            if (Object.keys(pointsBreakdown).length == 0) {
                console.log(`getting all activity summary scores for competition ${competition.id} and user ${userID}`);
                pointsBreakdown = await generateEntirePointsBreakdown(competition);
            } else {
                console.log(`getting activity summary score for competition ${competition.id} and user ${userID}`);
                const singlePointsBreakdown = generateSinglePointsBreakdown(competition);
                console.log(`activity summary score for competition ${competition.id} and user ${userID} for ${singlePointsBreakdown.id} is ${singlePointsBreakdown.points}`);
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
