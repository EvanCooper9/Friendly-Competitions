import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as moment from "moment";
import { deleteAccount } from "./Handlers/account/deleteAccount";
import { deleteCompetition } from "./Handlers/competitions/deleteCompetition";
import { updateCompetitionStandings } from "./Handlers/competitions/updateCompetitionStandings";
import { deleteFriend } from "./Handlers/friends/deleteFriend";
import { FriendRequestAction, handleFriendRequest } from "./Handlers/friends/handleFriendRequest";
import { ActivitySummary } from "./Models/ActivitySummary";
import { Competition } from "./Models/Competition";
import { Standing } from "./Models/Standing";
import { User } from "./Models/User";
import * as notifications from "./notifications";
import { getFirestore } from "./Utilities/firstore";

admin.initializeApp();
const firestore = getFirestore();

exports.deleteAccount = functions.https.onCall(async (_data, context) => {
    const userID = context.auth?.uid;
    if (userID == null) return;
    await deleteAccount(userID);
});

exports.sendFriendRequest = functions.https.onCall((data, context) => {
    const requesterID = context.auth?.uid;
    const requesteeID = data.userID;
    if (requesterID == null) return Promise.resolve();
    return handleFriendRequest(requesterID, requesteeID, FriendRequestAction.create);
});

exports.respondToFriendRequest = functions.https.onCall((data, context) => {
    const requesterID = context.auth?.uid;
    const requesteeID = data.userID;
    const accept = data.accept;
    if (requesterID == null) return Promise.resolve();
    return handleFriendRequest(requesterID, requesteeID, accept ? FriendRequestAction.accept : FriendRequestAction.decline);
});

exports.deleteFriend = functions.https.onCall((data, context) => {
    const userID = context.auth?.uid;
    const friendID = data.userID;
    if (userID == null) return Promise.resolve();
    return deleteFriend(userID, friendID);
});

exports.deleteCompetition = functions.https.onCall(data => {
    const competitionID = data.competitionID;
    return deleteCompetition(competitionID);
});

exports.updateCompetitionStandings = functions.https.onCall((_data, context) => {
    const userID = context.auth?.uid;
    if (userID == null) return Promise.resolve();
    return updateCompetitionStandings(userID);
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
        const newInvitees = newCompetition.pendingParticipants.filter(x => !oldInvitees.includes(x));
        if (oldInvitees == newInvitees || newInvitees.length == 0) return;

        const userPromises = await firestore.collection("users")
            .where("id", "in", newInvitees)
            .get();

        userPromises.docs
            .map(doc => new User(doc))
            .filter(user => !user.id.startsWith("Anonymous"))
            .forEach(async user => {
                const message = change.before.exists ?
                    `You've been invited to ${newCompetition.name}` : // invited by somebody to existing competition
                    `${owner.name} invited you to ${newCompetition.name}`; // invited by owner to new competition
                await notifications.sendNotificationsToUser(user, "Competition invite", message);
            });
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
            const notificationPromises = competition.participants
                .filter(participantId => !participantId.startsWith("Anonymous"))
                .map(async participantId => {
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

            return Promise
                .all(notificationPromises)
                .then(async () => {
                    await competition.updateRepeatingCompetition();
                    await competition.updateStandings();
                });
        });

        return Promise.all(competitionPromises);
    });
