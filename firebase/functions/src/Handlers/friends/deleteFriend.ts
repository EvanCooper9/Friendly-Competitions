import { User } from "../../Models/User";
import { getFirestore } from "../../Utilities/firestore";

/**
 * Deletes a friend
 * @param {string} userID the user deleting the friend
 * @param {string} friendID the friend to delete
 * @return {Promise<void>} A promise that resolves when complete
 */
async function deleteFriend(userID: string, friendID: string): Promise<void> {
    const firestore = getFirestore();
    
    const user = await firestore.doc(`users/${userID}`).get().then(doc => new User(doc));
    const friend = await firestore.doc(`users/${friendID}`).get().then(doc => new User(doc));

    const userFriends = user.friends;
    const userIndex = userFriends.indexOf(friendID);
    if (userIndex > -1) userFriends.splice(userIndex, 1);
    const friendFriends = friend.friends;
    const friendIndex = friendFriends.indexOf(userID);
    if (friendIndex > -1) friendFriends.splice(friendIndex, 1);

    const batch = firestore.batch();
    batch.update(firestore.doc(`users/${userID}`), {friends: userFriends});
    batch.update(firestore.doc(`users/${friendID}`), {friends: friendFriends});
    await batch.commit();
}

export {
    deleteFriend
};
