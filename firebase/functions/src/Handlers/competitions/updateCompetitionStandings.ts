import { Competition } from "../../Models/Competition";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Update a user's standings in all of their competitions
 * @param {string} userID the ID of the user to update competition standings for
 * @return {Promise<void>} A promise that resolves when completed
 */
function updateCompetitionStandings(userID: string): Promise<void> {
    const firestore = getFirestore();
    
    return firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)))
        .then(competitions => Promise.all(competitions.map(competition => competition.updateStandings())))
        .then();
}

export {
    updateCompetitionStandings
};
