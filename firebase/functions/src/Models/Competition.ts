import * as admin from "firebase-admin";
import * as moment from "moment";

/**
 * Competition
 */
class Competition {
    id: string;
    name: string;
    start: Date;
    end: Date;
    owner: string;
    participants: string[];
    pendingParticipants: string[];
    repeats: boolean;
    scoringModel: number;

    /**
     * Builds a competition from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the competition from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.id;
        this.name = document.get("name");
        this.owner = document.get("owner");
        this.participants = document.get("participants");
        this.pendingParticipants = document.get("pendingParticipants");
        this.repeats = document.get("repeats");
        this.scoringModel = document.get("scoringModel");

        const startDateString: string = document.get("start");
        const endDateString: string = document.get("end");
        this.start = new Date(startDateString);
        this.end = new Date(endDateString);
    }

    /**
     * Update a competition's start & end date if it is repeating
     * @param {Competition} competition The competition to update
     * @return {Promise<void>} A promise that completes when the update is finished
     */
    async updateRepeatingCompetition(): Promise<void> {
        if (!this.repeats) return Promise.resolve();

        const dateFormat = "yyyy-mm-dd";
        const competitionStart = moment(this.start);
        const competitionEnd = moment(this.end);
        if (competitionStart.day() == 1 && competitionEnd.day() == competitionEnd.daysInMonth()) {
            const newStart = competitionStart.add(1, "month");
            const newEnd = newStart.set("day", competitionStart.daysInMonth());
            this.start = new Date(newStart.format(dateFormat));
            this.end = new Date(newEnd.format(dateFormat));
        } else {
            const diff = competitionStart.diff(competitionEnd, "days");
            const newStart = competitionEnd.add(1, "days");
            const newEnd = newStart.add(diff, "days");
            this.start = new Date(newStart.format(dateFormat));
            this.end = new Date(newEnd.format(dateFormat));
        }
        return admin.firestore().doc(`competitions/${this.id}`)
            .set(this)
            .then();
    }
}

export {
    Competition
};
