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
    await Promise.all(competitions.map(async competition => await completeCompetition(competition)));
}

/**
 * Completes a competition
 * Completing a competition entails:
 * - Sending notifications to participants
 * - Updating history
 * - Resetting standings
 * - Resetting dates (if repeating)
 * @param {Compeittion} competition The competition to complete
 * @return {Promise<void>} A promise that resolves when complete
 */
async function completeCompetition(competition: Competition): Promise<void> {
    const firestore = getFirestore();
    const standings = await firestore.collection(`competitions/${competition.id}/standings`)
        .where("userId", "in", competition.participants)
        .get()
        .then(query => {
            return query.docs
                .map(doc => new Standing(doc))
                .sort((a, b) => a.userId.localeCompare(b.userId));
        });

    const users = await firestore.collection("users")
        .where("id", "in", competition.participants)
        .get()
        .then(query => {
            return query.docs
                .map(doc => new User(doc))
                .sort((a, b) => a.id.localeCompare(b.id));
        });

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
}

export {
    completeCompetitionsForYesterday,
    completeCompetitionsForDate
};
