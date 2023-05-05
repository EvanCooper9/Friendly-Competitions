import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";
import { RawScoringModel, ScoringModel } from "../../Models/ScoringModel";
import { Standing } from "../../Models/Standing";
import { setStandingRanks } from "../standings/setStandingRanks";

interface Scoring {
    id: string;
    date: Date;
    pointsForScoringModel(scoringModel: ScoringModel): number;
}

/**
 * Updates all standings for a competition
 * @param {DocumentSnapshot} before the competition document before the change
 * @param {DocumentSnapshot} after the competition document after the change
 * @return {Promise<void>} A promise that resolves when complete
 */
async function handleCompetitionUpdate(before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    const competition = new Competition(after);
    const competitionBefore = new Competition(before);
 
    const scoringModelChanged = competition.scoringModel != competitionBefore.scoringModel;
    const startDateChanged = competition.start != competitionBefore.start;
    const endDateChanged = competition.end != competitionBefore.end;
    if (scoringModelChanged || startDateChanged || endDateChanged) {
        await recalculateStandings(competition);
    }
}

/**
 * Updates all standings for a competition
 * @param {Competition} competition the competition to update standings for
 * @return {Promise<void>} A promise that resolves when complete
 */
async function recalculateStandings(competition: Competition): Promise<void> {    
    const standingResults = await Promise.allSettled(competition.participants.map(async participantID => {
        let scoringData: Scoring[];
        switch (competition.scoringModel.type) {
        case RawScoringModel.percentOfGoals:
            scoringData = await competition.activitySummaries(participantID);
            break;
        case RawScoringModel.rawNumbers:
            scoringData = await competition.activitySummaries(participantID);
            break;
        case RawScoringModel.workout:
            scoringData = await competition.workouts(participantID);
            break;
        }

        let totalPoints = 0;
        const pointsBreakdown: StringKeyDictionary<string, number> = {};
        scoringData.forEach(scoringDatum => {
            const points = scoringDatum.pointsForScoringModel(competition.scoringModel);
            totalPoints += points;
            pointsBreakdown[scoringDatum.id] = points;
        });
        const standing = Standing.new(totalPoints, participantID);
        standing.pointsBreakdown = pointsBreakdown;
        return standing;
    }));
    
    const standings = standingResults
        .filter(result => result.status == "fulfilled")
        .map(result =>(result as PromiseFulfilledResult<Standing>).value);

    await setStandingRanks(competition, standings);
}

export {
    handleCompetitionUpdate
};
