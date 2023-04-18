import moment = require("moment");
import { getFirestore } from "../../../Utilities/firstore";
import { Competition } from "../../../Models/Competition";
import { remoteConfig } from "firebase-admin";
import { Standing } from "../../../Models/Standing";

/**
 * Calculates competition scores
 */
async function calculateCompetitionScores(): Promise<void> {
    const template = await remoteConfig().getTemplate();
    const updateThresholdSecondsValue = template.parameters["standings_rank_update_interval"].defaultValue as remoteConfig.ExplicitParameterValue;
    
    const firestore = getFirestore();
    const now = moment();
    const updateThresholdSeconds: number = JSON.parse(updateThresholdSecondsValue.value);
    const updateCutoff = now.add(-updateThresholdSeconds, "seconds");

    console.log("update cutoff", updateCutoff);

    const competitions = await firestore.collection("competitions")
        .where("oldestStandingUpdate", "<=", updateCutoff.toDate().toISOString())
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    console.log(competitions);

    await Promise.allSettled(competitions.map(async competition => {
        console.log(`updating standing points for competition: ${competition.name} - ${competition.id}`);
        
        const standings = await firestore.collection(`competitions/${competition.id}/standings`)
            .get()
            .then(query => query.docs.map(doc => new Standing(doc)));

        const batch = firestore.batch();
        await Promise.allSettled(standings.map(async standing => {
            const pointsBreakdown = standing.pointsBreakdown || {};
            let points = 0;
            Object.keys(pointsBreakdown).forEach(key => points += pointsBreakdown[key]);
            const standingDoc = firestore.doc(`competitions/${competition.id}/standings/${standing.userId}`);
            batch.update(standingDoc, { points: points });
        }));
        await batch.commit();

        console.log(`updating standing ranks for competition: ${competition.name} - ${competition.id}`);
        await competition.updateStandingRanks();

        const obj = { oldestStandingUpdate: null };
        await firestore.doc(`competitions/${competition.id}`).update(obj);
    }));
}

export {
    calculateCompetitionScores
};
