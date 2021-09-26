import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as notifications from "./notifications";
admin.initializeApp();

const firestore = admin.firestore();

exports.sendIncomingFriendRequestNotification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async change => {
        const user = change.after.data();
        const newFriendRequests: string[] = user.incomingFriendRequests;
        const oldFriendRequests: string[] = change.before.data().incomingFriendRequests;

        if (newFriendRequests == oldFriendRequests) {
            return null;
        }

        const incomingFriends = newFriendRequests
            .filter((x: string) => !oldFriendRequests.includes(x))
            .map(incomingFriendId => {
                return admin.auth().getUser(incomingFriendId);    
            });

        return Promise.all(incomingFriends)
            .then(incomingFriends => {
                const notificationPromises = incomingFriends.map(incomingFriend => {
                    return notifications.sendNotifications(
                        user.id, 
                        "Friendly Competitions",
                        `${incomingFriend.displayName} added you as a friend`
                    );
                });
                return Promise.all(notificationPromises);
            });
    });

exports.sendNewCompetitionNotification = functions.firestore
    .document("competitions/{competitionId}")
    .onCreate(async snapshot => {
        const creatorPromise = await firestore.doc(`users/${snapshot.data().participants[0]}`).get();
        const creator = creatorPromise.data();
        const pendingParticipants: string[] = snapshot.data().pendingParticipants;

        if (creator == null) {
            return;
        }

        const pendingParticipantPromises = pendingParticipants.map(pendingParticipant => {
            return firestore.doc(`users/${pendingParticipant}`).get();
        });

        return Promise.all(pendingParticipantPromises)
            .then(pendingParticipants => {
                
                if (pendingParticipants == null) {
                    return null;
                }

                const notificationPromises = pendingParticipants.map(pendingParticipant => {
                    const user = pendingParticipant.data();   
                    
                    if (user == null) {
                        return Promise.resolve();
                    }

                    return notifications.sendNotifications(
                        user.id,
                        "Friendly Competitions",
                        `${creator.name} invited you to a competition`
                    );
                });

                return Promise.all(notificationPromises);
            });
    });
