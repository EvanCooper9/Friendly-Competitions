/**
 * Prepare an object for Firestore
 * @param {any} object a JSON object ready for firestore upload
 */
function prepareForFirestore(object: any): any {
    return Object.assign({}, object);
}

export {
    prepareForFirestore
};
