import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { deleteAccount } from "./Handlers/account/deleteAccount";
import { deleteCompetition } from "./Handlers/competitions/deleteCompetition";
import { respondToCompetitionInvite } from "./Handlers/competitions/respondToCompetitionInvite";
import { inviteUserToCompetition } from "./Handlers/competitions/inviteUserToCompetition";
import { updateCompetitionStandings } from "./Handlers/competitions/updateCompetitionStandings";
import { deleteFriend } from "./Handlers/friends/deleteFriend";
import { FriendRequestAction, handleFriendRequest } from "./Handlers/friends/handleFriendRequest";
import { joinCompetition } from "./Handlers/competitions/joinCompetition";
import { leaveCompetition } from "./Handlers/competitions/leaveCompetition";
import { cleanActivitySummaries } from "./Handlers/jobs/cleanActivitySummaries";
import { sendCompetitionCompleteNotifications } from "./Handlers/jobs/sendCompetitionCompleteNotifications";
import { sendNewCompetitionInvites } from "./Handlers/competitions/sendNewCompetitionInvites";

admin.initializeApp();

// Account

exports.deleteAccount = functions.https.onCall(async (_data, context) => {
    const userID = context.auth?.uid;
    if (userID == null) return;
    await deleteAccount(userID);
});

// Competitions 

exports.deleteCompetition = functions.https.onCall(data => {
    const competitionID = data.competitionID;
    return deleteCompetition(competitionID);
});

exports.inviteUserToCompetition = functions.https.onCall((data, context) => {
    const caller = context.auth?.uid;
    const competitionID = data.competitionID;
    const userID: string = data.userID;
    if (caller == null) return Promise.resolve();
    return inviteUserToCompetition(competitionID, caller, userID);
});

exports.respondToCompetitionInvite = functions.https.onCall((data, context) => {
    const caller = context.auth?.uid;
    const competitionID = data.competitionID;
    const accept = data.accept;
    if (caller == null) return Promise.resolve();
    return respondToCompetitionInvite(competitionID, caller, accept);
});

exports.updateCompetitionStandings = functions.https.onCall((_data, context) => {
    const userID = context.auth?.uid;
    if (userID == null) return Promise.resolve();
    return updateCompetitionStandings(userID);
});

exports.joinCompetition = functions.https.onCall((data, context) => {
    const competitionID = data.competitionID;
    const userID = context.auth?.uid;
    if (userID == null) return Promise.resolve();
    return joinCompetition(competitionID, userID);
});

exports.leaveCompetition = functions.https.onCall((data, context) => {
    const competitionID = data.competitionID;
    const userID = context.auth?.uid;
    if (userID == null) return Promise.resolve();
    return leaveCompetition(competitionID, userID);
});

exports.sendNewCompetitionInvites = functions.firestore
    .document("competitions/{competitionID}")
    .onCreate((snapshot, context) => {
        const competitionID: string = context.params.competitionID;
        return sendNewCompetitionInvites(competitionID);
    });

// Friends

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

// Jobs

exports.cleanStaleActivitySummaries = functions.pubsub.schedule("every day 02:00")
    .timeZone("America/Toronto")
    .onRun(async () => cleanActivitySummaries());

exports.sendCompetitionCompleteNotifications = functions.pubsub.schedule("every day 12:00")
    .timeZone("America/Toronto")
    .onRun(async () => sendCompetitionCompleteNotifications());
