import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { StringKeyDictionary } from "../../Models/Helpers/EnumDictionary";
import { RawScoringModel, ScoringModel } from "../../Models/ScoringModel";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";
import { updateCompetitionRanks } from "../competitions/updateCompetitionRanks";

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
        await updateAllCompetitionStandings(competition);
    }
}

/**
 * Updates all standings for a competition
 * @param {Competition} competition the competition to update standings for
 * @return {Promise<void>} A promise that resolves when complete
 */
async function updateAllCompetitionStandings(competition: Competition): Promise<void> {
    const firestore = getFirestore();
    const batch = firestore.batch();
    
    await Promise.all(competition.participants.map(async participantID => {
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
        
        const standingRef = firestore.doc(`competitions/${competition.id}/standings/${participantID}`);
        batch.set(standingRef, prepareForFirestore(standing));
    }));
    await batch.commit();
    await updateCompetitionRanks(competition.id);
}

export {
    handleCompetitionUpdate
};
