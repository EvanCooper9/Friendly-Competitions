import * as admin from "firebase-admin";
import { User } from "../../Models/User";

/**
 * Sends a notification to all of a user's notification tokens
 * @param {User} user The user to send the notification to
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @param {string?} deepLink (Optional) A deep link for navigation when interacting with a notification
 */
async function sendNotificationsToUser(user: User, title: string, body: string, deepLink?: string): Promise<void> {
    const tokens = user.notificationTokens;
    if (tokens === undefined) return;

    console.log(`sending notifications to user ${user.id}`);
    const tokensToDelete: string[] = [];
    const notifications = tokens.map(async token => {
        try {
            await sendNotification(token, title, body, deepLink);
            console.log(`successfully sent notification to user ${user.id} - ${token}`);
        } catch (error) {
            // error likely due to invalid token... so remove it.
            // not the end of the world if the error is something else, 
            // token will be re-uploaded from the app at some point.
            console.error(`error sending notification: ${error}`);
            tokensToDelete.push(token);
        }
    });

    await Promise.allSettled(notifications);
    const activeTokens = tokens.filter(t => !tokensToDelete.includes(t));
    await admin.firestore().doc(`users/${user.id}`).update({ notificationTokens: activeTokens });
}

/**
 * Send a single notification for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @param {string?} deepLink (Optional) A deep link for navigation when interacting with a notification
 */
async function sendNotification(fcmToken: string, title: string, body: string, deepLink?: string) {
    const notificationPayload = {
        token: fcmToken,
        data: {},
        notification: {
            title: title,
            body: body
        }
    };
    console.log(`sending notification payload: ${JSON.stringify(notificationPayload)}`);
    if (deepLink != null) notificationPayload.data = { link: deepLink };
    await admin.messaging().send(notificationPayload);
}

export {
    sendNotificationsToUser
};
