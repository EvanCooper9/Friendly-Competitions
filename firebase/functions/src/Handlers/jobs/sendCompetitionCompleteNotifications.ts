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
    const competitions = await firestore.collection("competitions")
        .where("end", "==", yesterday.format("YYYY-MM-DD"))
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.all(competitions.map(async competition => {
        const standings = await firestore.collection(`competitions/${competition.id}/standings`)
            .orderBy("id", "desc")
            .where("id", "in", competition.participants)
            .get()
            .then(query => query.docs.map(doc => new Standing(doc)));

        const users = await firestore.collection("users")
            .orderBy("id", "desc")
            .where("id", "in", competition.participants)
            .get()
            .then(query => query.docs.map(doc => new User(doc)));

        if (standings.length != users.length) {
            console.error(`Standings (count: ${standings.length}) or users (count: ${users.length}) are missing from competition: ${competition.id}`);
            return;
        }
        const pairs = users.map((user, index) => {
            // assume that order is the same, based on firestore query
            return { user: user, standing: standings[index] };
        });

        await Promise.all(pairs.map(async pair => {
            const rank = pair.standing.rank;
            const ordinal = ["st", "nd", "rd"][((rank+90)%100-10)%10-1] || "th";
            await notifications.sendNotificationsToUser(
                pair.user,
                "Competition complete!",
                `You placed ${rank}${ordinal} in ${competition.name}. Tap to see your results.`,
                `https://friendly-competitions.app/competition/${competition.id}/results`
            );
            await pair.user.updateStatisticsWithNewRank(rank);
        }));

        await competition.recordResults();
        await competition.updateRepeatingCompetition();
        await competition.resetStandings();
    }));
}

export {
    sendCompetitionCompleteNotifications
};
