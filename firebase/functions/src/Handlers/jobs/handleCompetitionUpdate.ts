import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { updateAllCompetitionStandings } from "./updateAllCompetitionStandings";

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

export {
    handleCompetitionUpdate,
};
