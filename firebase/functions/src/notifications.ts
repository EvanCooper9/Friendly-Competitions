import * as admin from "firebase-admin";
import { User } from "./Models/User";

/**
 * Sends a notification to all of a user's notification tokens
 * @param { User } user The user to send the notification to
 * @param { string } title The title of the notification
 * @param { string } body The body of the notification
 * @return { Promise<void> } A Promise for all notifications that are sent
 */
async function sendNotificationsToUser(user: User, title: string, body: string): Promise<void> {
    const tokens = user.notificationTokens;
    if (tokens === undefined) return;
    const notifications = tokens.map(async token => {
        return await sendNotification(token, title, body)
            .catch(() => {
                // error likely due to invalid token... so remove it.
                // not the end of the world if the error is something else, 
                // token will be re-uploaded from the app at some point.
                const activeTokens = tokens.filter(t => t != token);
                return admin.firestore().doc(`users/${user.id}`).update({ notificationTokens: activeTokens });
            });
    });

    return Promise.all(notifications).then();
}

/**
 * Send a single notificaiton for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @return {Promise<void>} A Promise for the notification being sent
 */
async function sendNotification(fcmToken: string, title: string, body: string): Promise<void> {
    const notificationPayload = {
        token: fcmToken,
        notification: {
            title: title,
            body: body
        }
    };
    
    return admin.messaging()
        .send(notificationPayload)
        .then();
}

export {
    sendNotificationsToUser
};
