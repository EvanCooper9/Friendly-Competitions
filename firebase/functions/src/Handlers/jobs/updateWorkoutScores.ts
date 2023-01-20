import { DocumentSnapshot } from "firebase-admin/firestore";
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { Workout } from "../../Models/Workout";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

async function updateWorkoutScores(userID: string, before?: DocumentSnapshot, after?: DocumentSnapshot) {
    const firestore = getFirestore();
    const competitionsRef = await firestore.collection(`competitions`)
        .where("participants", "array-contains", userID)
        .get();
    const competitions = competitionsRef.docs.map(doc => new Competition(doc));

    await competitions.forEach(async competition => {
        if (!competition.isActive()) return;

        const standingDoc = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
        const standingRef = await standingDoc.get();        
        let standing = Standing.new(0, userID);
        if (standingRef.exists) standing = new Standing(standingRef);

        let pointsDiff = 0;
        if (after == null && before != undefined) { // deleted
            const beforeWorkout = new Workout(before);
            if (!beforeWorkout.isIncludedInCompetition(competition)) return;
            // pointsDiff = -beforeWorkout.points;
        } else if (before == null && after != undefined) { // created
            const afterWorkout = new Workout(after);
            if (!afterWorkout.isIncludedInCompetition(competition)) return;
            // pointsDiff = afterWorkout.points;
        } else if (before != null && after != null) { // updated
            const beforeWorkout = new Workout(before);
            const afterWorkout = new Workout(after);
            if (!beforeWorkout.isIncludedInCompetition(competition)) return;
            if (!afterWorkout.isIncludedInCompetition(competition)) return;
            // pointsDiff = afterWorkout.points - beforeWorkout.points;
        }
        standing.points += pointsDiff;

        await standingDoc.set(prepareForFirestore(standing));
        await competition.updateStandingRanks();
    });
}

export {
    updateWorkoutScores
};
