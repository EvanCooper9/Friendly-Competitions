import { DocumentSnapshot } from "firebase-admin/firestore";
import { sendNewCompetitionInvites } from "../competitions/sendNewCompetitionInvites";
import { Competition } from "../../Models/Competition";
import { updateAllCompetitionStandings } from "./updateAllCompetitionStandings";

async function handleCompetitionCreate(snapshot: DocumentSnapshot): Promise<void> {
    const competition = new Competition(snapshot);
    await updateAllCompetitionStandings(competition);
    await sendNewCompetitionInvites(competition.id);
}

export {
    handleCompetitionCreate
};
