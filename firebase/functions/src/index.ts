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
import { updateUserCompetitionStandingsLEGACY, updateCompetitionStandingsLEGACY } from "./Handlers/competitions/updateCompetitionStandingsLEGACY";
import { updateActivitySummaryScores } from "./Handlers/jobs/updateActivitySummaryScores";
import { updateWorkoutScores } from "./Handlers/jobs/updateWorkoutScores";
import { updateCompetitionRanks } from "./Handlers/competitions/updateCompetitionRanks";
import { handleCompetitionUpdate } from "./Handlers/jobs/handleCompetitionUpdate";
import { sendBackgroundNotification } from "./Handlers/notifications/notifications";
import { updateStepCountScores } from "./Handlers/jobs/updateStepCountScores";
import { handleCompetitionCreate } from "./Handlers/jobs/handleCompetitionCreate";
import { saveSWAToken } from "./Handlers/account/signInWithAppleToken";
import { accountSetup } from "./Handlers/account/accountSetup";

admin.initializeApp();

// Account

exports.deleteAccount = functions
    .runWith({ secrets: ["TEAM_ID", "PRIVATE_KEY", "PRIVATE_KEY_DBG", "KEY_ID", "KEY_ID_DBG"]})
    .https.onCall(async (_data, context) => {
        const userID = context.auth?.uid;
        const clientID = context.app?.appId;
        if (userID == null || clientID == null) {
            console.log("failed to invoke function");
            console.log(`userID: ${userID}`);
            console.log(`clientID: ${clientID}`);
            return;
        }
        await deleteAccount(userID, clientID);
    });

exports.saveSWAToken = functions
    .runWith({ secrets: ["TEAM_ID", "PRIVATE_KEY", "PRIVATE_KEY_DBG", "KEY_ID", "KEY_ID_DBG"]})
    .https.onCall(async (data, context) => {
        const code = data.code;
        const userID = context.auth?.uid;
        const clientID = context.app?.appId;
        if (userID == null || clientID == null) {
            console.log("failed to invoke function");
            console.log(`code: ${code}`);
            console.log(`userID: ${userID}`);
            console.log(`userID: ${clientID}`);
            return;
        }
        await saveSWAToken(code, userID, clientID);
    });

exports.accountSetup = functions.firestore
    .document("users/{userID}")
    .onCreate(async (_snapshot, context) => { 
        const userID = context.params.userID;
        await accountSetup(userID);
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

exports.handleCompetitionCreate = functions.firestore
    .document("competitions/{competitionID}")
    .onCreate(async (snapshot) => {
        await handleCompetitionCreate(snapshot);
    });

exports.handleCompetitionUpdate = functions.firestore
    .document("competitions/{competitionID}")
    .onUpdate(async snapshot => {
        const before = snapshot.before;
        const after = snapshot.after;
        await handleCompetitionUpdate(before, after);
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

exports.updateStepCountScores = functions.firestore
    .document("users/{userID}/steps/{stepCountID}")
    .onWrite(async (snapshot, context) => {
        const userID = context.params.userID;
        const before = snapshot.before;
        const after = snapshot.after;
        await updateStepCountScores(userID, before, after);
    });

exports.updateWorkoutScores = functions.firestore
    .document("users/{userID}/workouts/{workoutID}")
    .onWrite(async (snapshot, context) => {
        const userID = context.params.userID;
        const before = snapshot.before;
        const after = snapshot.after;
        await updateWorkoutScores(userID, before, after);
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
    console.log("sending notification");
    const token = "d8tiU6vZbU23uiIg1wdI5w:APA91bFOW4-w4VB4X7fx4mD5WwxMPwKtw1pegGUPquJt4jx2zK_95YKzv9G7Sx7hhNchS4iEw-GmFID4MsRP7x_e4CdRA1rzrWzDs6TGrCHA64NUZL-myuW16VyKu1FxPjBKO80OXCT-";
    const competitionBackgroundJob = {
        documentPath: "competitions/09FCAD9F-7A18-40B3-A2A5-3B497CAFCA80",
        competitionIDForResults: "09FCAD9F-7A18-40B3-A2A5-3B497CAFCA80"
    };
    await sendBackgroundNotification(token, competitionBackgroundJob);
});
