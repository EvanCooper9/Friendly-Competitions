import { DocumentSnapshot } from "firebase-admin/firestore";
import { sendNewCompetitionInvites } from "../competitions/sendNewCompetitionInvites";
import { Competition } from "../../Models/Competition";
import { recalculateStandings } from "./handleCompetitionUpdate";

/**
 * Performs actions necessary when creating a competition
 * @param {DocumentSnapshot} snapshot the snapshot of the created competition
 */
async function handleCompetitionCreate(snapshot: DocumentSnapshot) {
    const competitionID: string = snapshot.id;
    await sendNewCompetitionInvites(competitionID);
    
    const competition = new Competition(snapshot);
    await recalculateStandings(competition);
}

export {
    handleCompetitionCreate
};
