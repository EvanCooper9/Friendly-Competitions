import { DocumentSnapshot } from "firebase-admin/firestore";
import { getFirestore } from "../../Utilities/firestore";
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { StepCount } from "../../Models/StepCount";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

async function updateStepCountScores(userID: string, before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
    const firestore = getFirestore();

    const competitions = await firestore.collection("competitions")
        .where("participants", "array-contains", userID)
        .where("scoringModel.type", "==", 4)
        .get()
        .then(query => query.docs.map(doc => new Competition(doc)));

    await Promise.allSettled(competitions.map(async competition => {
        const date = new Date(after.id);
        if (date < competition.start || date > competition.end) return;

        await firestore.runTransaction(async transaction => {
            const standingRef = firestore.doc(`competitions/${competition.id}/standings/${userID}`);
            const standingDoc = await transaction.get(standingRef);
            let standing = Standing.new(0, userID);
            if (standingDoc.exists) standing = new Standing(standingDoc);
    
            const pointsBreakdown = standing.pointsBreakdown ?? {};
            if (Object.keys(pointsBreakdown).length == 0) {
                const stepCounts = await competition.stepCounts(userID);
                stepCounts.forEach(stepCount => {
                    const points = stepCount.pointsForScoringModel(competition.scoringModel);
                    pointsBreakdown[stepCount.id] = points;
                });
            } else {
                if (after.exists) { // created or updated
                    const stepCount = new StepCount(after);
                    pointsBreakdown[stepCount.id] = stepCount.pointsForScoringModel(competition.scoringModel);
                } else { // deleted
                    pointsBreakdown[before.id] = 0;
                }
            }
            
            standing.pointsBreakdown = pointsBreakdown;
            standing.points = 0;
            Object.keys(pointsBreakdown).forEach(key => standing.points += pointsBreakdown[key]);
            transaction.set(standingRef, prepareForFirestore(standing));
        });
    }));
}

export {
    updateStepCountScores
};
