import { joinCompetition } from "../competitions/joinCompetition";

/**
 * Performs setup actions for a new account
 * @param {string} userID the ID of the user who's account to setup
 */
async function accountSetup(userID: string): Promise<void> {
    const competitionIDs = [
        "V7AJuKqhek6kVcrSWwRa", // weekly
        "xdsAs5bEIiOKh12nqxdy", // monthly
        "ZkFLFkAdMWWhgF2FIUqu" // steps
    ];

    const joinCompetitions = competitionIDs.map(competitionID => {
        return joinCompetition(competitionID, userID);    
    });

    await Promise.all(joinCompetitions);
}

export {
    accountSetup
};
