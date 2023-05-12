import * as admin from "firebase-admin";

let shared: admin.firestore.Firestore | null = null;

/**
 * Get a shared firestore instance
 * @return {admin.firestore.Firestore} the shared instance
 */
function getFirestore(): admin.firestore.Firestore {
    if (shared != null) {
        return shared;
    }
    const firestore = admin.firestore();
    firestore.settings({
        ignoreUndefinedProperties: true
    });
    shared = firestore;
    return firestore;
}

export {
    getFirestore
};
