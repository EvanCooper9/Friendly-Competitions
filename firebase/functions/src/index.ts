import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as moment from "moment";
import { ActivitySummary } from "./Models/ActivitySummary";
import { Competition } from "./Models/Competition";
import { Standing } from "./Models/Standing";
import { User } from "./Models/User";
import * as notifications from "./notifications";

admin.initializeApp();
const firestore = admin.firestore();

exports.sendIncomingFriendRequestNotification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async change => {
        const oldUser = new User(change.before);
        const newUser = new User(change.after);
        const newFriendRequests: string[] = newUser.incomingFriendRequests;
        const oldFriendRequests: string[] = oldUser.incomingFriendRequests;
        if (newFriendRequests == oldFriendRequests) return;

        const notificationPromises = newFriendRequests
            .filter(x => !oldFriendRequests.includes(x))
            .map(async newFriendId => {
                const authUser = await admin.auth().getUser(newFriendId);
                return await notifications.sendNotificationsToUser(
                    newUser,
                    "Friendly Competitions",
                    `${authUser.displayName} added you as a friend`
                );
            });

        return Promise.all(notificationPromises);
    });

exports.sendNewCompetitionNotification = functions.firestore
    .document("competitions/{competitionId}")
    .onWrite(async change => {
        if (!change.after.exists) return; // deleted

        const oldCompetition = new Competition(change.before);
        const newCompetition = new Competition(change.after);

        const ownerData = await firestore.doc(`users/${newCompetition.owner}`).get();
        const owner = new User(ownerData);

        let oldInvitees = oldCompetition.pendingParticipants;
        if (oldInvitees == undefined) oldInvitees = [];
        const newInvitees = newCompetition.pendingParticipants;
        if (oldInvitees == newInvitees || newInvitees.length == 0) return;

        const userPromises = await firestore.collection("users")
            .where("id", "in", newInvitees.filter(x => !oldInvitees.includes(x)))
            .get();

        const users = userPromises.docs.map(doc => new User(doc));
        const notificationPromises = users.map(user => {
            const message = change.before.exists ?
                `You've been invited to ${newCompetition.name}` : // invited by somebody to existing competition
                `${owner.name} invited you to ${newCompetition.name}`; // invited by owner to new competition
            return notifications.sendNotificationsToUser(user, "Competition invite", message);
        });

        return Promise.all(notificationPromises);
    });

exports.updateCompetitionStandings = functions.https
    .onCall(async data => {
        const userId = data.userId;
        const competitionsRef = await firestore.collection("competitions")
            .where("participants", "array-contains", userId)
            .get();
        const competitions = competitionsRef.docs.map(doc => new Competition(doc));

        const updateCompetitions = competitions.map(async competition => {
            let totalPoints = 0;
            const activitySummaries = (await firestore.collection(`users/${userId}/activitySummaries`).get()).docs.map(doc => new ActivitySummary(doc));
            activitySummaries.forEach(activitySummary => {
                if (!activitySummary.isIncludedInCompetition(competition)) return;
                if (competition.scoringModel == 0) {
                    const energy = (activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal) * 100;
                    const exercise = (activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal) * 100;
                    const stand = (activitySummary.appleStandHours / activitySummary.appleStandHoursGoal) * 100;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                } else if (competition.scoringModel == 1) {
                    const energy = activitySummary.activeEnergyBurned;
                    const exercise = activitySummary.appleExerciseTime;
                    const stand = activitySummary.appleStandHours;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                }
            });

            let existingStanding: Standing | null = null;
            let standings = (await firestore.collection(`competitions/${competition.id}/standings`).get()).docs.map(doc => new Standing(doc));
            standings = standings.map(standing => {
                if (standing.userId == userId) {
                    standing.points = totalPoints;
                    existingStanding = standing;
                }
                return standing;
            });
            if (existingStanding == null) standings.push(Standing.new(totalPoints, userId));
            
            const updateStandings = standings
                .sort((a, b) => a.points > b.points ? 1 : -1)
                .reverse()
                .map((standing, index) => {
                    standing.rank = index + 1;
                    const obj = Object.assign({}, standing);
                    return firestore.doc(`competitions/${competition.id}/standings/${standing.userId}`).set(obj);
                });
            
            return Promise.all(updateStandings);
        });

        return Promise.all(updateCompetitions);
    });

exports.cleanStaleActivitySummaries = functions.pubsub.schedule("every day 02:00")
    .timeZone("America/Toronto")
    .onRun(async () => {
        const users = (await firestore.collection("users").get()).docs.map(doc => new User(doc));
        const competitions = (await firestore.collection("competitions").get()).docs.map(doc => new Competition(doc));
        const cleanUsers = users.map(async user => {
            const participatingCompetitions = competitions.filter(competition => competition.participants.includes(user.id));
            const activitySummariesToDelete = (await firestore.collection(`users/${user.id}/activitySummaries`).get())
                .docs
                .filter(doc => {
                    const activitySummary = new ActivitySummary(doc);
                    const matchingCompetition = participatingCompetitions.find(competition => activitySummary.isIncludedInCompetition(competition));
                    return matchingCompetition == null || matchingCompetition == undefined;
                })
                .map(doc => firestore.doc(`users/${user.id}/activitySummaries/${doc.id}`).delete());

            return Promise.all(activitySummariesToDelete);
        });
        
        return Promise.all(cleanUsers);
    });

exports.sendCompetitionCompleteNotifications = functions.pubsub.schedule("every day 12:00")
    .timeZone("America/Toronto")
    .onRun(async () => {
        const competitionsRef = await firestore.collection("competitions").get();
        const competitionPromises = competitionsRef.docs.map(async doc => {
            const competition = new Competition(doc);
            
            const competitionEnd = moment(competition.end);
            const yesterday = moment().utc().subtract(1, "day");
            if (yesterday.dayOfYear() != competitionEnd.dayOfYear() || yesterday.year() != competitionEnd.year()) return;

            const standingsRef = await firestore.collection(`competitions/${competition.id}/standings`).get();
            const standings = standingsRef.docs.map(doc => new Standing(doc));
            const notificationPromises = competition.participants.map(async participantId => {
                const userRef = await firestore.doc(`users/${participantId}`).get();
                const user = new User(userRef);
                const standing = standings.find(standing => standing.userId == user.id);
                if (standing == null) return null;

                const rank = standing.rank;
                const ordinal = ["st", "nd", "rd"][((rank+90)%100-10)%10-1] || "th";
                return notifications
                    .sendNotificationsToUser(
                        user,
                        "Competition complete!",
                        `You placed ${rank}${ordinal} in ${competition.name}!`
                    )
                    .then(() => user.updateStatisticsWithNewRank(rank));
            });

            return Promise.all(notificationPromises)
                .then(() => competition.repeats ? competition.updateRepeatingCompetition() : Promise.resolve());
        });

        return Promise.all(competitionPromises);
    });
