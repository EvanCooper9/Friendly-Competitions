import fetch from "node-fetch";
import { defineSecret } from "firebase-functions/params";
const firebaseAppId = defineSecret("FIREBASE_APP_ID");
const analyticsApiKey = defineSecret("ANALYTICS_API_KEY");
const appInstanceId = defineSecret("APP_INSTANCE_ID");

enum Event {
    databaseRead = "database_read",
    databaseWrite = "database_write"
}

enum EventParameterKey {
    path = "path",
    source = "source"
}

type EventParameters = {
    [key in EventParameterKey]?: any
}

/**
 * Logs an analytic event
 * @param {Event} event The event to log
 * @param {EventParameters} params The parameters to log
 */
async function logEvent(event: Event, params: EventParameters): Promise<void> {
    params[EventParameterKey.source] = "functions";
    console.log(`logging event: ${event} with parameters: ${JSON.stringify(params)}`);
    await fetch(`https://www.google-analytics.com/mp/collect?firebase_app_id=${firebaseAppId}&api_secret=${analyticsApiKey}`, {
        method: "POST",
        body: JSON.stringify({
            app_instance_id: appInstanceId,
            events: [{
                name: event,
                params: params,
            }]
        })
    });
}

export {
    Event,
    EventParameterKey,
    EventParameters,
    logEvent
};
