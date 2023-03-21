import { Competition } from "../../Models/Competition";
import { RawScoringModel } from "../../Models/ScoringModel";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Update a user's standings in all of their competitions
 * @param {string} userID the ID of the user to update competition standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
async function updateUserCompetitionStandingsLEGACY(userID: string): Promise<void> {
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));
    
    await Promise.allSettled(competitions.map(async competition => {
        await updateStandings(competition);
    }));
}

/**
 * Update a competitions's standings
 * @param {string} competitionID the ID of the competition to update standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
async function updateCompetitionStandingsLEGACY(competitionID: string): Promise<void> {
    const firestore = getFirestore();
    const competition = await firestore.doc(`competitions/${competitionID}`).get().then(doc => new Competition(doc));
    await updateStandings(competition);
}

/**
 * Updates the points and standings
 * @param {CompositionEventInit} competition the competition to update the standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
async function updateStandings(competition: Competition): Promise<void> {
    console.log(`USING DEPRECATED STANDINGS UPDATE, COMPETITION: ${competition.id}`);
    const standings = await Promise.allSettled(competition.participants.map(async userId => {
        let totalPoints = 0;
        switch (competition.scoringModel.type) {
        case RawScoringModel.percentOfGoals: {
            const activitySummaries = await competition.activitySummaries(userId);
            activitySummaries.forEach(activitySummary => {
                totalPoints += activitySummary.pointsForScoringModel(competition.scoringModel);
            });
            break;
        }
        case RawScoringModel.rawNumbers: {
            const activitySummaries = await competition.activitySummaries(userId);
            activitySummaries.forEach(activitySummary => {
                totalPoints += activitySummary.pointsForScoringModel(competition.scoringModel);
            });
            break;
        }
        case RawScoringModel.workout: {
            const workouts = await competition.workouts(userId);
            workouts.forEach(workout => {
                totalPoints += workout.pointsForScoringModel(competition.scoringModel);
            });
            break;
        }
        }
        return Standing.new(totalPoints, userId);
    }));

    const firestore = getFirestore();
    const batch = firestore.batch();
    standings
        .sort((a, b) => a.points > b.points ? 1 : -1)
        .reverse()
        .forEach((standing, index) => {
            standing.rank = index + 1;
            const obj = Object.assign({}, standing);
            const ref = firestore.doc(`competitions/${competition.id}/standings/${standing.userId}`);
            batch.set(ref, obj);
        });
    await batch.commit();
}

export {
    updateUserCompetitionStandingsLEGACY,
    updateCompetitionStandingsLEGACY
};
