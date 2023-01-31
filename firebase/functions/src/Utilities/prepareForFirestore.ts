/**
 * Prepare an object for Firestore
 * @param {any} object a JSON object ready for firestore upload
 * @return {any} the object ready for Firestore upload
 */
function prepareForFirestore(object: any): any {
    return Object.assign({}, object);
}

export {
    prepareForFirestore
};
