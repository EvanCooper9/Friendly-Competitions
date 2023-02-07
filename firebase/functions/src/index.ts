import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { deleteAccount } from "./Handlers/account/deleteAccount";
import { deleteCompetition } from "./Handlers/competitions/deleteCompetition";
import { respondToCompetitionInvite } from "./Handlers/competitions/respondToCompetitionInvite";
import { inviteUserToCompetition } from "./Handlers/competitions/inviteUserToCompetition";
import { deleteFriend } from "./Handlers/friends/deleteFriend";
import { FriendRequestAction, handleFriendRequest } from "./Handlers/friends/handleFriendRequest";
import { joinCompetition } from "./Handlers/competitions/joinCompetition";
import { leaveCompetition } from "./Handlers/competitions/leaveCompetition";
import { cleanActivitySummaries } from "./Handlers/jobs/cleanActivitySummaries";
import { sendCompetitionCompleteNotifications } from "./Handlers/jobs/sendCompetitionCompleteNotifications";
import { sendNewCompetitionInvites } from "./Handlers/competitions/sendNewCompetitionInvites";
import { updateCompetitionRanks } from "./Handlers/competitions/updateCompetitionRanks";
import { updateUserCompetitionStandingsLEGACY, updateCompetitionStandingsLEGACY } from "./Handlers/competitions/updateCompetitionStandingsLEGACY";
import { updateActivitySummaryScores } from "./Handlers/jobs/updateActivitySummaryScores";
import { updateWorkoutScores } from "./Handlers/jobs/updateWorkoutScores";
import { handleCompetitionUpdate } from "./Handlers/jobs/updateCompetitionStandings";

admin.initializeApp();

// Account

exports.deleteAccount = functions.https.onCall(async (_data, context) => {
    const userID = context.auth?.uid;
    if (userID == null) return;
    await deleteAccount(userID);
});

// Competitions 

exports.deleteCompetition = functions.https.onCall(async data => {
    const competitionID = data.competitionID;
    await deleteCompetition(competitionID);
});

exports.inviteUserToCompetition = functions.https.onCall(async (data, context) => {
    const caller: string | undefined = context.auth?.uid;
    const competitionID = data.competitionID;
    const userID: string = data.userID;
    if (caller == null) return;
    await inviteUserToCompetition(competitionID, caller, userID);
});

exports.respondToCompetitionInvite = functions.https.onCall(async (data, context) => {
    const caller = context.auth?.uid;
    const competitionID: string = data.competitionID;
    const accept = data.accept;
    if (caller == null) return;
    await respondToCompetitionInvite(competitionID, caller, accept);
});

exports.updateCompetitionStandingsRanks = functions.https.onCall(async data => {
    const competitionID = data.competitionID;
    if (competitionID == null) return;
    await updateCompetitionRanks(competitionID);
});

exports.updateCompetitionStandings = functions.https.onCall(async (data, context) => {
    const competitionID = data.competitionID;
    if (competitionID == undefined) {
        const userID = context.auth?.uid;
        if (userID == null) return Promise.resolve();
        await updateUserCompetitionStandingsLEGACY(userID);
    } else {
        await updateCompetitionStandingsLEGACY(competitionID);
    }
});

exports.joinCompetition = functions.https.onCall(async (data, context) => {
    const competitionID: string = data.competitionID;
    const userID: string | undefined = context.auth?.uid;
    if (userID == null) return;
    await joinCompetition(competitionID, userID);
});

exports.leaveCompetition = functions.https.onCall(async (data, context) => {
    const competitionID = data.competitionID;
    const userID: string | undefined = context.auth?.uid;
    if (userID == undefined) return;
    await leaveCompetition(competitionID, userID);
});

exports.sendNewCompetitionInvites = functions.firestore
    .document("competitions/{competitionID}")
    .onCreate(async (_snapshot, context) => {
        const competitionID: string = context.params.competitionID;
        await sendNewCompetitionInvites(competitionID);
    });

// Friends

exports.sendFriendRequest = functions.https.onCall(async (data, context) => {
    const requesterID = context.auth?.uid;
    const requesteeID = data.userID;
    if (requesterID == null) return;
    await handleFriendRequest(requesterID, requesteeID, FriendRequestAction.create);
});

exports.respondToFriendRequest = functions.https.onCall(async (data, context) => {
    const requesterID = context.auth?.uid;
    const requesteeID = data.userID;
    const accept = data.accept;
    if (requesterID == null) return;
    await handleFriendRequest(requesterID, requesteeID, accept ? FriendRequestAction.accept : FriendRequestAction.decline);
});

exports.deleteFriend = functions.https.onCall(async (data, context) => {
    const userID = context.auth?.uid;
    const friendID = data.userID;
    if (userID == null) return;
    await deleteFriend(userID, friendID);
});

// Points

exports.updateActivitySummaryScores = functions.firestore
    .document("users/{userID}/activitySummaries/{activitySummaryID}")
    .onWrite(async (snapshot, context) => {
        const userID = context.params.userID;
        const before = snapshot.before;
        const after = snapshot.after;
        await updateActivitySummaryScores(userID, before, after);
    });

exports.updateWorkoutScores = functions
    .runWith({ timeoutSeconds: 540 })
    .firestore
    .document("users/{userID}/workouts/{workoutID}")
    .onWrite(async (snapshot, context) => {
        const userID = context.params.userID;
        const before = snapshot.before;
        const after = snapshot.after;
        await updateWorkoutScores(userID, before, after);
    });

exports.onCompetitionUpdate = functions.firestore
    .document("competitions/{competitionID}")
    .onUpdate(async snapshot => {
        const before = snapshot.before;
        const after = snapshot.after;
        await handleCompetitionUpdate(before, after);
    });

// Jobs

exports.cleanActivitySummaries = functions.pubsub.schedule("every Sunday 02:00")
    .timeZone("America/Toronto")
    .onRun(async () => await cleanActivitySummaries());

exports.sendCompetitionCompleteNotifications = functions.pubsub.schedule("every day 12:00")
    .timeZone("America/Toronto")
    .onRun(async () => await sendCompetitionCompleteNotifications());
