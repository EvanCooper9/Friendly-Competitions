import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Update a user's standings in all of their competitions
 * @param {string} userID the ID of the user to update competition standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
function updateUserCompetitionStandings(userID: string): Promise<void> {
    return getFirestore().collection("competitions")
        .where("participants", "array-contains", userID)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)))
        .then(competitions => Promise.all(competitions.map(competition => competition.updateStandings())))
        .then();
}

/**
 * Update a competitions's standings
 * @param {string} competitionID the ID of the competition to update standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
function updateCompetitionStandings(competitionID: string): Promise<void> {
    return getFirestore().doc(`competitions/${competitionID}`)
        .get()
        .then(doc => new Competition(doc))
        .then(competition => competition.updateStandings());
}

export {
    updateUserCompetitionStandings,
    updateCompetitionStandings
};
