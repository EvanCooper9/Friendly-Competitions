/**
 * Standing
 */
class Standing {
    points: number;
    rank: number;
    userId: string;

    /**
     * Builds a standing record from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the standing record from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.points = document.get("points");
        this.rank = document.get("rank");
        this.userId = document.get("user");
    }

    /**
     * Creates a new standing record
     * @param {number} points number of points
     * @param {string} userId The id if the user
     * @return {Standing} a new standing
     */
    static new(points: number, userId: string): Standing {
        return { points: points, rank: 0, userId: userId }; 
    }
}

export {
    Standing
};
