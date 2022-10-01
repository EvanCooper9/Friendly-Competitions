/**
 * Creates an id
 * @return {string} an id
 */
function id(): string {
    // Math.random should be unique because of its seeding algorithm.
    // Convert it to base 36 (numbers + letters), and grab the first 9 characters
    // after the decimal.
    return Math.random().toString(36).substring(2).toUpperCase();
}

export {
    id
};
