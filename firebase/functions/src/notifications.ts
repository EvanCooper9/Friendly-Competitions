import * as admin from "firebase-admin";
import { User } from "./Models/User";

/**
 * Sends a notification to all of a user's notification tokens
 * @param { User } user The user to send the notification to
 * @param { string } title The title of the notification
 * @param { string } body The body of the notification
 */
async function sendNotificationsToUser(user: User, title: string, body: string) {
    const tokens = user.notificationTokens;
    if (tokens === undefined) return;
    const notifications = tokens.map(async token => {
        try {
            return await sendNotification(token, title, body);
        } catch {
            // error likely due to invalid token... so remove it.
            // not the end of the world if the error is something else, 
            // token will be re-uploaded from the app at some point.
            return token;
        }
    });

    const tokensToDelete = await Promise.all(notifications);
    const activeTokens = tokens.filter(t => !tokensToDelete.includes(t));
    await admin.firestore().doc(`users/${user.id}`).update({ notificationTokens: activeTokens });
}

/**
 * Send a single notification for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 */
async function sendNotification(fcmToken: string, title: string, body: string) {
    const notificationPayload = {
        token: fcmToken,
        notification: {
            title: title,
            body: body
        }
    };
    
    await admin.messaging().send(notificationPayload);
}

export {
    sendNotificationsToUser
};
