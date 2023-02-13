import moment = require("moment");
import { Competition } from "../../Models/Competition";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";
import { RawScoringModel } from "../../Models/ScoringModel";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";

async function calculateCompetitionScores(): Promise<void> {
    const firestore = getFirestore();
    const today = moment().format("YYYY-MM-DD");
    const competitions = await firestore.collection("competitions")
        .where("start", ">=", today)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));
    
    await Promise.all(competitions.map(async competition => {
        await Promise.all(competition.participants.map(async userID => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standing = await standingRef.get().then(doc => new Standing(doc));
            const scoringModelType = RawScoringModel.toString(competition.scoringModel.type);
            const points = await firestore.doc(`users/${userID}/points/${scoringModelType}`)
                .get()
                .then(doc => doc.data() as StringKeyDictionary<string, number>);

            let totalPoints = 0;
            Object.keys(points).forEach(x => totalPoints += points[x]);
            standing.points = totalPoints;
            standing.pointsBreakdown = points;

            await standingRef.set(standing);
        }));
        await competition.updateStandingRanks();
    }));
}

export {
    calculateCompetitionScores
};
