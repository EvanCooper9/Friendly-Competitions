import { User } from "../../Models/User";
import { sendNotificationsToUser } from "../notifications/notifications";
import { getFirestore } from "../../Utilities/firstore";
import { Constants } from "../../Utilities/Constants";

/**
 * FriendRequestAction
 */
enum FriendRequestAction {
    create,
    accept,
    decline
}

/**
 * Create, accept, or decline friend requests
 * @param {string} callerID The ID of the requester
 * @param {string} requesteeID The ID of the requestee
 * @param {FriendRequestAction} action The action to perform
 * @return {Promise<void>} A promise that resolves when the action is complete
 */
async function handleFriendRequest(callerID: string, requesteeID: string, action: FriendRequestAction): Promise<void> {
    const firestore = getFirestore();
    
    const caller = await firestore.doc(`users/${callerID}`).get().then(doc => new User(doc));
    const requestee = await firestore.doc(`users/${requesteeID}`).get().then(doc => new User(doc));

    const callerFriends = caller.friends;
    const requesteeFriends = requestee.friends;
    const callerOutgoingFriendRequests: string[] = caller.outgoingFriendRequests;
    const callerIncomingFriendRequests: string[] = caller.incomingFriendRequests;
    const requesteeOutgoingFriendRequests: string[] = requestee.outgoingFriendRequests;
    const requesteeIncomingFriendRequests: string[] = requestee.incomingFriendRequests;

    switch (action) {
    case FriendRequestAction.create:
        if (!callerOutgoingFriendRequests.includes(requesteeID)) callerOutgoingFriendRequests.push(requesteeID);
        if (!requesteeIncomingFriendRequests.includes(callerID)) requesteeIncomingFriendRequests.push(callerID);
        break;
    case FriendRequestAction.accept: {
        if (!callerFriends.includes(requesteeID)) callerFriends.push(requesteeID);
        if (!requesteeFriends.includes(callerID)) requesteeFriends.push(callerID);

        const callerOutgoingIndex = callerOutgoingFriendRequests.indexOf(requesteeID);
        if (callerOutgoingIndex > -1) callerOutgoingFriendRequests.splice(callerOutgoingIndex, 1);
        const callerIncomingIndex = callerIncomingFriendRequests.indexOf(requesteeID);
        if (callerIncomingIndex > -1) callerIncomingFriendRequests.splice(callerIncomingIndex, 1);

        const requesteeOutgoingIndex = requesteeOutgoingFriendRequests.indexOf(callerID);
        if (requesteeOutgoingIndex > -1) requesteeOutgoingFriendRequests.splice(requesteeOutgoingIndex, 1);
        const requesteeIncomingIndex = requesteeIncomingFriendRequests.indexOf(callerID);
        if (requesteeIncomingIndex > -1) requesteeIncomingFriendRequests.splice(requesteeIncomingIndex, 1);
        break;
    }
    case FriendRequestAction.decline: {
        const callerOutgoingIndex = callerOutgoingFriendRequests.indexOf(requesteeID);
        if (callerOutgoingIndex > -1) callerOutgoingFriendRequests.splice(callerOutgoingIndex, 1);
        const callerIncomingIndex = callerIncomingFriendRequests.indexOf(requesteeID);
        if (callerIncomingIndex > -1) callerIncomingFriendRequests.splice(callerIncomingIndex, 1);

        const requesteeOutgoingIndex = requesteeOutgoingFriendRequests.indexOf(callerID);
        if (requesteeOutgoingIndex > -1) requesteeOutgoingFriendRequests.splice(requesteeOutgoingIndex, 1);
        const requesteeIncomingIndex = requesteeIncomingFriendRequests.indexOf(callerID);
        if (requesteeIncomingIndex > -1) requesteeIncomingFriendRequests.splice(requesteeIncomingIndex, 1);
        break;
    }
    }

    const batch = firestore.batch();
    batch.update(firestore.doc(`users/${callerID}`), {
        friends: callerFriends,
        incomingFriendRequests: callerIncomingFriendRequests,
        outgoingFriendRequests: callerOutgoingFriendRequests
    });
    batch.update(firestore.doc(`users/${requesteeID}`), {
        friends: requesteeFriends,
        incomingFriendRequests: requesteeIncomingFriendRequests,
        outgoingFriendRequests: requesteeOutgoingFriendRequests
    });
    await batch.commit();

    const title = "Friendly Competitions";
    const url = `${Constants.NOTIFICATION_URL}/user/${caller.id}`;
    switch (action) {
    case FriendRequestAction.create:
        await sendNotificationsToUser(
            requestee,
            title,
            `${caller.name} added you as a friend`,
            url
        );
        break;
    case FriendRequestAction.accept:
        await sendNotificationsToUser(
            requestee,
            title,
            `${caller.name} accepted your friend request`,
            url
        );
        break;
    case FriendRequestAction.decline:
        break;
    }
}

export {
    FriendRequestAction,
    handleFriendRequest
};
