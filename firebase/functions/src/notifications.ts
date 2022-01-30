import * as admin from "firebase-admin";

/**
 * Sends a notification to all of a user's notification tokens
 * @param {string} userId The id of the user 
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @return {Promise<string[]>} A Promise for all notifications that are sent
 */
function sendNotifications(userId: string, title: string, body: string): Promise<void> {
    return admin.firestore().doc(`users/${userId}`).get()
        .then(snapshot => {
            const user = snapshot.data();

            if (user == null) {
                return Promise.resolve([]);
            }

            const tokens: string[] = user.notificationTokens;
            if (tokens == null) {
                return Promise.resolve([]);
            }

            const notifications = tokens.map(token => {
                return sendNotification(token, title, body);
            });

            return Promise.all(notifications);
        })
        .then(messageIds => {
            return;
        });
}

/**
 * Send a single notificaiton for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @return {Promise<string[]>} A Promise for the notification being sent
 */
function sendNotification(fcmToken: string, title: string, body: string): Promise<string> {

    console.log(`Sending notification to token: ${fcmToken}`);

    const notificationPayload = {
        token: fcmToken,
        notification: {
            title: title,
            body: body
        }
    };
    
    return admin.messaging().send(notificationPayload)
        .then(messageId => {
            console.log(`Sent notification with messageId: ${messageId}`);
            return messageId; 
        });
}

export {
    sendNotifications as sendNotifications
};
