import * as jwt from "jsonwebtoken";
import("node-fetch");
import { getFirestore } from "../../Utilities/firestore";

interface Map {
    [key: string]: string | undefined
}

interface AppleAuthTokenResponse {
    // eslint-disable-next-line camelcase
    refresh_token: string
}

/**
 * Fetches and stores a refresh token for SWA.
 * Needs the current environment variables: TEAM_ID, KEY_ID
 * @param {string} code the code received by the mobile client after successful SWA
 * @param {string} userID the id of the user for which to fetch and store the token
 * @param {string} clientID the bundle identifier of the client
 * @return {Promise<void>} a promise that resolves when completed
 */
async function saveSWAToken(code: string, userID: string, clientID: string): Promise<void> {
    const firestore = getFirestore();

    const resolvedClientID = resolveClientID(clientID);
    
    const data: Map = {
        "code": code,
        "client_id": resolvedClientID,
        "client_secret": makeJWT(resolvedClientID),
        "grant_type": "authorization_code"
    };

    const response = await post("https://appleid.apple.com/auth/token", data);
    const result = (await response.json()) as AppleAuthTokenResponse;
    await firestore.doc(`swaTokens/${userID}`).set({ swaRefreshToken: result.refresh_token });
}

/**
 * Revokes the stored SWA refresh token. Expects the user to be deleted after.
 * Needs the current environment variables: TEAM_ID, KEY_ID
 * @param {string} userID the id of the user for which to revoke the token
 * @param {string} clientID the bundle identifier of the client
 * @return {Promise<void>} a promise that resolves when completed
 */
async function revokeSWAToken(userID: string, clientID: string): Promise<void> {
    const firestore = getFirestore();
    const refreshToken: string = await firestore.doc(`swaTokens/${userID}`).get().then(doc => doc.get("swaRefreshToken"));

    const resolvedClientID = resolveClientID(clientID);

    const data = {
        "token": refreshToken,
        "client_id": resolvedClientID,
        "client_secret": makeJWT(resolvedClientID),
        "token_type_hint": "refresh_token"
    };

    await post("https://appleid.apple.com/auth/revoke", data);
    await firestore.doc(`swaTokens/${userID}`).delete();
}

/**
 * Resolves a google client ID to a bundle identifier
 * @param {string} googleClientID the google client id
 * @return {string} the bundle identifier
 */
function resolveClientID(googleClientID: string): string {
    const clientIdMap: Map = {
        "1:787056522440:ios:c0fd8dabecf3d15bc121fd": "com.evancooper.FriendlyCompetitions",
        "1:787056522440:ios:7f8c86b5fa545ff7c121fd": "com.evancooper.FriendlyCompetitions.debug"
    };

    return clientIdMap[googleClientID] ?? "";
}

/**
 * Send a post request to the URL with the data
 * @param {string} url the url to send the request to
 * @param {Map} data the data to send
 * @return {Promise<Response>} a promise for the request
 */
function post(url: string, data: Map): Promise<Response> {
    const body = Object
        .keys(data)
        .map((key: string) => encodeURIComponent(key) + "=" + encodeURIComponent(data[key] ?? "undefined"))
        .join("&");

    const requestOptions = {
        method: "POST",
        body: body,
        headers: {
            "Content-Type": "application/x-www-form-urlencoded"
        }
    };

    return fetch(url, requestOptions);
}

/**
 * Create a JWT for fetching/revoking SWA refresh tokens
 * @param {string} clientID the client ID to generate the JWT for
 * @return {string} the JWT
 */
function makeJWT(clientID: string): string {
    
    const teamID = process.env.TEAM_ID;
    
    let privateKey;
    let keyID;
    if (clientID == "com.evancooper.FriendlyCompetitions") {
        privateKey = process.env.PRIVATE_KEY;
        keyID = process.env.KEY_ID;
    } else if (clientID == "com.evancooper.FriendlyCompetitions.debug") {
        privateKey = process.env.PRIVATE_KEY_DBG;
        keyID = process.env.KEY_ID_DBG;
    }

    if (teamID !== undefined && keyID !== undefined && privateKey !== undefined) {
        const privateKeyBuffer = Buffer.from(privateKey, "base64");

        return jwt.sign(
            { 
                iss: teamID,
                iat: Math.floor(Date.now() / 1000),
                exp: Math.floor(Date.now() / 1000) + 1200000,
                aud: "https://appleid.apple.com",
                sub: clientID
            }, 
            privateKeyBuffer, 
            { 
                algorithm: "ES256",
                header: {
                    alg: "ES256",
                    kid: keyID,
                } 
            }
        );
    } else {
        return "";
    }
}

export {
    saveSWAToken,
    revokeSWAToken
};
