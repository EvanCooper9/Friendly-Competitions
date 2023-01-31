import moment = require("moment");
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { User } from "../../Models/User";
import { getFirestore } from "../../Utilities/firstore";
import * as notifications from "../notifications/notifications";

/**
 * Sends notifications to competition participants, updates history, and resets repeating competitions.
 * @return {Promise<void>} A promise that resolves when complete
 */
async function sendCompetitionCompleteNotifications(): Promise<void> { 
    const firestore = getFirestore();

    const yesterday = moment().utc().subtract(1, "day");
    const competitionsRef = await firestore.collection("competitions")
        .where("end", "==", yesterday.format("YYYY-MM-DD"))
        .get();

    const competitionPromises = competitionsRef.docs.map(async doc => {
        const competition = new Competition(doc);
        const standingsRef = await firestore.collection(`competitions/${competition.id}/standings`).get();
        const standings = standingsRef.docs.map(doc => new Standing(doc));
        const notificationPromises = competition.participants.map(async participantId => {
            const userRef = await firestore.doc(`users/${participantId}`).get();
            const user = new User(userRef);
            const standing = standings.find(standing => standing.userId == user.id);
            if (standing == null) return Promise.resolve();

            const rank = standing.rank;
            const ordinal = ["st", "nd", "rd"][((rank+90)%100-10)%10-1] || "th";
            return notifications
                .sendNotificationsToUser(
                    user,
                    "Competition complete!",
                    `You placed ${rank}${ordinal} in ${competition.name}. Tap to see your results.`,
                    `https://friendly-competitions.app/competition/${competition.id}/history`
                )
                .then(() => user.updateStatisticsWithNewRank(rank));
        });

        return Promise.all(notificationPromises)
            .then(async () => {
                await competition.recordResults();
                await competition.updateRepeatingCompetition();
                await competition.resetStandings();
            });
    });

    return Promise.all(competitionPromises).then();
}

export {
    sendCompetitionCompleteNotifications
};
