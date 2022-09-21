import { User } from "../../Models/User";
import { getFirestore } from "../../Utilities/firstore";

/**
 * Deletes a friend
 * @param {string} userID the user deleting the friend
 * @param {string} friendID the friend to delete
 * @return {Promise<void>} A promise that resolves when complete
 */
async function deleteFriend(userID: string, friendID: string): Promise<void> {
    const firestore = getFirestore();
    
    const user = firestore.doc(`users/${userID}`)
        .get()
        .then(doc => new User(doc));

    const friend = firestore.doc(`users/${friendID}`)
        .get()
        .then(doc => new User(doc));

    return Promise.all([user, friend])
        .then(result => {
            const user = result[0];
            const friend = result[1];

            const userFriends = user.friends;
            const userIndex = userFriends.indexOf(friendID);
            if (userIndex > -1) userFriends.splice(userIndex, 1);
            const friendFriends = friend.friends;
            const friendIndex = friendFriends.indexOf(userID);
            if (friendIndex > -1) friendFriends.splice(friendIndex, 1);

            const batch = firestore.batch();
            batch.update(firestore.doc(`users/${userID}`), {friends: userFriends});
            batch.update(firestore.doc(`users/${friendID}`), {friends: friendFriends});
            return batch.commit();
        })
        .then();
}

export {
    deleteFriend
};
