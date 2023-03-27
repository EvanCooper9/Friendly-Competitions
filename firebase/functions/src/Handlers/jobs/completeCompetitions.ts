import moment = require("moment");
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { User } from "../../Models/User";
import { getFirestore } from "../../Utilities/firstore";
import * as notifications from "../notifications/notifications";

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
    await Promise.allSettled(competition.participants.map(async userID => {
        const user = await firestore.doc(`users/${userID}`).get().then(doc => new User(doc));
        const standing = await firestore.doc(`competitions/${competition.id}/standings/${userID}`).get().then(doc => new Standing(doc));
        const rank = standing.rank;
        const ordinal = ["st", "nd", "rd"][((rank+90)%100-10)%10-1] || "th";
        await notifications.sendNotificationsToUser(
            user,
            "Competition complete!",
            `You placed ${rank}${ordinal} in ${competition.name}. Tap to see your results.`,
            `https://friendly-competitions.app/competition/${competition.id}/results`
        );
        await user.updateStatisticsWithNewRank(rank);
    }));

    await competition.recordResults();
    await competition.kickInactiveUsers();
    await competition.resetStandings();
    await competition.updateRepeatingCompetition();
}

export {
    completeCompetitionsForYesterday,
    completeCompetitionsForDate
};
