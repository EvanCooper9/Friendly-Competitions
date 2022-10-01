import * as admin from "firebase-admin";

interface Statistics {
    golds: number;
    silvers: number;
    bronzes: number;
}

/**
 * User
 */
class User {
    id: string;
    name: string;
    friends: string[];
    incomingFriendRequests: string[];
    outgoingFriendRequests: string[];
    notificationTokens: string[];
    statistics: Statistics;

    /**
     * Builds a user from a firestore document
     * @param {FirebaseFirestore.DocumentSnapshot} document The firestore document to build the user from
     */
    constructor(document: FirebaseFirestore.DocumentSnapshot) {
        this.id = document.id;
        this.name = document.get("name");
        this.friends = document.get("friends");
        this.incomingFriendRequests = document.get("incomingFriendRequests");
        this.outgoingFriendRequests = document.get("outgoingFriendRequests");
        this.notificationTokens = document.get("notificationTokens");
        this.statistics = document.get("statistics");
    }

    /**
     * Updates a user's statistics with a new rank
     * @param {number} rank The new rank
     * @return {Promise<void>} A promise that completes when the update is finished
     */
    async updateStatisticsWithNewRank(rank: number): Promise<void> {
        let statistics = this.statistics;
        if (statistics == null) statistics = {golds: 0, silvers: 0, bronzes: 0};
        
        if (rank == 1) {
            statistics.golds += 1;
        } else if (rank == 2) {
            statistics.silvers += 1;
        } else if (rank == 3) {
            statistics.bronzes += 1;
        } else { 
            // Don't need to update stats
            return Promise.resolve();
        }

        this.statistics = statistics;
        return admin.firestore().doc(`users/${this.id}`)
            .update({statistics: statistics})
            .then();
    }
}

export { 
    User
};
