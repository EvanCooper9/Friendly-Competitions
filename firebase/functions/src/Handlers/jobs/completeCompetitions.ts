import moment = require("moment");
import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { Constants } from "../../Utilities/Constants";
import { getFirestore } from "../../Utilities/firestore";
import * as notifications from "../notifications/notifications";
import { recalculateStandings } from "./handleCompetitionUpdate";

/**
 * Completes all competitions that ended yesterday
 * Completing a competition entails:
 * - Sending notifications to participants
 * - Updating history
 * - Resetting standings
 * - Resetting dates (if repeating)
 * @return {Promise<void>} A promise that resolves when complete
 */
async function completeCompetitionsForYesterday(): Promise<void> { 
    const yesterday = moment().utc().subtract(1, "day");
    await completeCompetitionsForDate(yesterday.format("YYYY-MM-DD"));
}

/**
 * Completes all competitions that end on a specified date
 * Completing a competition entails:
 * - Sending notifications to participants
 * - Updating history
 * - Resetting standings
 * - Resetting dates (if repeating)
 * @param {string} date the date that competitions ended on
 * @return {Promise<void>} A promise that resolves when complete
 */
async function completeCompetitionsForDate(date: string): Promise<void> {
    const firestore = getFirestore();
    const competitions = await firestore.collection("competitions")
        .where("end", "==", date)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));
    await Promise.allSettled(competitions.map(async competition => await completeCompetition(competition)));
}

/**
 * Completes a competition
 * Completing a competition entails:
 * - Sending notifications to participants
 * - Updating history
 * - Resetting standings
 * - Resetting dates (if repeating)
 * @param {Competition} competition The competition to complete
 * @return {Promise<void>} A promise that resolves when complete
 */
async function completeCompetition(competition: Competition): Promise<void> {
    const firestore = getFirestore();

    console.log(`completing competition ${competition.id}`);

    const results = await competition.recordResults();
    console.log(`recorded results ${competition.id}`);

    results.forEach(async standing => {
        const user = await firestore.doc(`users/${standing.userId}`).get().then(doc => new User(doc));
        const rank = standing.rank;
        const ordinal = ["st", "nd", "rd"][((rank+90)%100-10)%10-1] || "th";
        const yesterday = moment().utc().subtract(1, "day").format("YYYY-MM-DD");
        await notifications.sendNotificationsToUser(
            user,
            "Competition complete!",
            `You placed ${rank}${ordinal} in ${competition.name}. Tap to see your results.`,
            `${Constants.NOTIFICATION_URL}/competition/${competition.id}/results/${yesterday}`
        );
        await notifications.sendBackgroundNotificationToUser(
            user,
            {
                documentPath: `competitions/${competition.id}`,
                competitionIDForResults: competition.id
            }
        );
        await user.updateStatisticsWithNewRank(rank);
    });
    console.log(`sent notifications ${competition.id}`);

    if (competition.owner == "com.evancooper.FriendlyCompetitions") {
        await competition.kickInactiveUsers();
        console.log(`kicked inactive users ${competition.id}`);
    }

    if (competition.repeats) {
        await competition.updateRepeatingCompetition();
        console.log(`updated dates ${competition.id}`);

        await recalculateStandings(competition);
        console.log(`recalculated standings ${competition.id}`);
    }
}

export {
    completeCompetitionsForYesterday,
    completeCompetitionsForDate
};
