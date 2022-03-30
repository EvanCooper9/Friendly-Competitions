/**
 * Standing
 */
class Standing {
    points: number;
    rank: number;
    userId: string;
    date?: string;

    /**
     * Builds a standing record from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the standing record from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.points = document.get("points");
        this.rank = document.get("rank");
        this.userId = document.get("userId");
        this.date = document.get("date");
    }

    /**
     * Creates a new standing record
     * @param {number} points number of points
     * @param {string} userId The id if the user
     * @return {Standing} a new standing
     */
    static new(points: number, userId: string): Standing {
        const date = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
        return { points: points, rank: 0, userId: userId, date: date }; 
    }
}

export {
    Standing
};
