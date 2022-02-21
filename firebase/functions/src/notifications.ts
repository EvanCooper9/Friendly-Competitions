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
            const notifications = tokens.map(async token => {
                try {
                    return await sendNotification(token, title, body);
                } catch (error) {
                    // error likely due to invalid notification token... so remove it.
                    const activeTokens = tokens.filter((t) => t != token);
                    user.notificationTokens = activeTokens;
                    return await snapshot.ref.update(user);
                }
            });

            return Promise.all(notifications);
        })
        .then();
}

/**
 * Send a single notificaiton for a given token
 * @param {string} fcmToken The token to send the notification for
 * @param {string} title The title of the notification
 * @param {string} body The body of the notification
 * @return {Promise<string[]>} A Promise for the notification being sent
 */
function sendNotification(fcmToken: string, title: string, body: string): Promise<void> {

    console.log(`Sending notification to token: ${fcmToken}`);

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
    sendNotifications as sendNotifications
};
