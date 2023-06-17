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
import { completeCompetitionsForYesterday } from "./Handlers/jobs/completeCompetitions";
import { sendNewCompetitionInvites } from "./Handlers/competitions/sendNewCompetitionInvites";
import { updateUserCompetitionStandingsLEGACY, updateCompetitionStandingsLEGACY } from "./Handlers/competitions/updateCompetitionStandingsLEGACY";
import { updateActivitySummaryScores } from "./Handlers/jobs/updateActivitySummaryScores";
import { updateWorkoutScores } from "./Handlers/jobs/updateWorkoutScores";
import { updateCompetitionRanks } from "./Handlers/competitions/updateCompetitionRanks";
import { handleCompetitionUpdate } from "./Handlers/jobs/handleCompetitionUpdate";
import { sendBackgroundNotification, sendNotification } from "./Handlers/notifications/notifications";

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
        if (userID == null) return;
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

exports.updateWorkoutScores = functions.firestore
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

// exports.cleanScoringData = functions.pubsub.schedule("every day 02:00")
//     .timeZone("America/Toronto")
//     .onRun(async () => {
//         await cleanupActivitySummaries();
//         await cleanupWorkouts();
//     });

exports.completeCompetitions = functions.pubsub.schedule("every day 12:00")
    .timeZone("America/Toronto")
    .onRun(async () => await completeCompetitionsForYesterday());

exports.dev_sendBackgroundNotification = functions.https.onCall(async () => {
    console.log("sending notification")
    // const token = "dIyKpoB0tkZvoEAyvOwWaR:APA91bEdR2k-bSOy4GLqG0q8nBkD-_b7cmdHZZhoyT7EjeGBKSgyxHoWp4MLbNP6HR6oLCKfIzmy2bjE7kW8-UrCk_RVqAld70wYFsRIN2DCHYqDUamQhOTlohVFVUhsxhGZJg9I-s8N";
    const token = "erqZvd5o1UdnncDtDOVdBm:APA91bHvr1nzRfPOlejECo_2XZX_czvAl9LLB6SMDqnRB4Oa3bdax-pdJ53seb4hKpox923gavP76Jq6Pu7ek1zENTHsA7Ehr6DvdALki4yBoJDefe7tkbtKV48b53nDdDCOUZ0afZ9E";
    const competitionBackgroundJob = {
        documentPath: "competitions/6A9405AC-F85C-4A0A-8DE7-3D03C783B0CF"
    };
    await sendBackgroundNotification(token, competitionBackgroundJob);
    await sendNotification(token, "Test", "test body");

    // const resultsBackgroundJob = {
    //     documentPath: "competitions/6A9405AC-F85C-4A0A-8DE7-3D03C783B0CF",
    //     competitionIDForResults: "6A9405AC-F85C-4A0A-8DE7-3D03C783B0CF"
    // };
    // await sendBackgroundNotification(token, resultsBackgroundJob);
});