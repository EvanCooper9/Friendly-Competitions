const fetch = require('node-fetch');
const { defineSecret } = require('firebase-functions/params');
const firebaseAppId = defineSecret('FIREBASE_APP_ID');
const analyticsApiKey = defineSecret('ANALYTICS_API_KEY');
const appInstanceId = defineSecret('APP_INSTANCE_ID');

enum Event {
    database_read = "database_read",
    database_write = "database_write"
}

enum EventParameterKey {
    path = "path",
    source = "source"
}

async function logEvent(event: Event, params: { [key in EventParameterKey]?: any }) {
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
    logEvent
};
