import { Competition } from "../../Models/Competition";
import { User } from "../../Models/User";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Deletes an account and all user data
 * @param {string} userID the user ID of the account to delete
 */
async function deleteAccount(userID: string) {
    const firestore = getFirestore();

    const batch = firestore.batch();

    // remove from competitions
    (await firestore.collection("competitions").where("participants", "array-contains", userID).get())
        .forEach(doc => {
            const competition = new Competition(doc);
            const participants = competition.participants;
            participants.remove(userID);
            batch.update(firestore.doc(`competitions/${competition.id}`), {participants: participants});
            batch.delete(firestore.doc(`competitions/${competition.id}/standings/${userID}`));
        });

    // remove from competition invites
    (await firestore.collection("competitions").where("pendingParticipants", "array-contains", userID).get())
        .forEach(doc => {
            const competition = new Competition(doc);
            const pendingParticipants = competition.pendingParticipants;
            pendingParticipants.remove(userID);
            batch.update(firestore.doc(`competitions/${competition.id}`), {pendingParticipants: pendingParticipants});
        });
    
    // remove from friends
    (await firestore.collection("users").where("friends", "array-contains", userID).get())
        .forEach(doc => {
            const user = new User(doc);
            const friends = user.friends;
            friends.remove(userID);
            batch.update(firestore.doc(`users/${user.id}`), {friends: friends});
        });

    // remove outgoing friend requests
    (await firestore.collection("users").where("incomingFriendRequests", "array-contains", userID).get())
        .forEach(doc => {
            const user = new User(doc);
            const incomingFriendRequests = user.incomingFriendRequests;
            incomingFriendRequests.remove(userID);
            batch.update(firestore.doc(`users/${user.id}`), {incomingFriendRequests: incomingFriendRequests});
        });

    // remove incoming friend requests
    (await firestore.collection("users").where("outgoingFriendRequests", "array-contains", userID).get())
        .forEach(doc => {
            const user = new User(doc);
            const outgoingFriendRequests = user.outgoingFriendRequests;
            outgoingFriendRequests.remove(userID);
            batch.update(firestore.doc(`users/${user.id}`), {outgoingFriendRequests: outgoingFriendRequests});
        });

    await batch.commit();
    await firestore.recursiveDelete(firestore.doc(`users/${userID}`));
}

export {
    deleteAccount
};
