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

    const tokensToDelete: string[] = [];
    const notifications = tokens.map(async token => {
        try {
            await sendNotification(token, title, body, deepLink);
        } catch (error) {
            // error likely due to invalid token... so remove it.
            // not the end of the world if the error is something else, 
            // token will be re-uploaded from the app at some point.
            console.error(`error sending notification to user ${user.id}: ${error}`);
            tokensToDelete.push(token);
        }
    });

    await Promise.allSettled(notifications);
    
    if (tokensToDelete.length == 0) return;
    const activeTokens = tokens.filter(t => !tokensToDelete.includes(t));
    await admin.firestore().doc(`users/${user.id}`).update({ notificationTokens: activeTokens });
}

/**
 * Sends a background notifications to all of a user's notification tokens
 * @param {User} user  The user to send to notifications to
 * @param {any?} backgroundJob The data to send to the client
 * @return {Promise<void>} A promise that resolves when complete
 */
async function sendBackgroundNotificationToUser(user: User, backgroundJob?: any): Promise<void> {
    const tokens = user.notificationTokens;
    if (tokens === undefined) return;

    const tokensToDelete: string[] = [];
    const notifications = tokens.map(async token => {
        try {
            await sendBackgroundNotification(token, backgroundJob);
        } catch (error) {
            // error likely due to invalid token... so remove it.
            // not the end of the world if the error is something else, 
            // token will be re-uploaded from the app at some point.
            console.error(`error sending notification to user ${user.id}: ${error}`);
            tokensToDelete.push(token);
        }
    });

    await Promise.allSettled(notifications);
    
    if (tokensToDelete.length == 0) return;
    const activeTokens = tokens.filter(t => !tokensToDelete.includes(t));
    await admin.firestore().doc(`users/${user.id}`).update({ notificationTokens: activeTokens });
}

/**
 * Send a single notification for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @param {string?} deepLink (Optional) A deep link for navigation when interacting with a notification
 * @return {Promise<void>} A promise that resolves when complete
 */
async function sendNotification(fcmToken: string, title: string, body: string, deepLink?: string): Promise<void> {
    const notificationPayload = {
        token: fcmToken,
        data: {},
        notification: {
            title: title,
            body: body
        }
    };
    if (deepLink != null) notificationPayload.data = { link: deepLink };
    await admin.messaging().send(notificationPayload);
}

/**
 * Send a single background notification for a given token
 * @param {string} fcmToken  The token to send the notification for
 * @param {any?} backgroundJob The data to send to the client
 * @return {Promise<void>} A promise that resolves when complete
 */
async function sendBackgroundNotification(fcmToken: string, backgroundJob?: any): Promise<void> {
    const notificationPayload = {
        token: fcmToken,
        apns: {
            headers: {
                "apns-push-type": "background",
                "apns-priority": "5"
            },
            payload: {
                aps: {
                    contentAvailable: true
                },
                customData: {
                    backgroundJob: backgroundJob
                }
            }
        }
    };
    const id = await admin.messaging().send(notificationPayload);
    console.log(`background notification response id: ${id}`);
}

export {
    sendNotificationsToUser,
    sendNotification,
    sendBackgroundNotificationToUser,
    sendBackgroundNotification
};
