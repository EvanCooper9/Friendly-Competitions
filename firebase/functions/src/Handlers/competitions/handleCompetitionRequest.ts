import { getFirestore } from "../../Utilities/firstore";

/**
 * CompetitionRequestAction
 */
enum CompetitionRequestAction {
    create,
    accept,
    decline
}

function handleCompetitionRequest(competitionID: string, action: CompetitionRequestAction): Promise<void> {
    const firestore = getFirestore();


}

export {
    handleCompetitionRequest
};
