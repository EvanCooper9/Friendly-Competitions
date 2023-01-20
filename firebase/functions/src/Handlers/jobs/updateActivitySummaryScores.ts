import { DocumentSnapshot } from "firebase-admin/firestore";
import { ActivitySummary } from "../../Models/ActivitySummary";
import { Competition } from "../../Models/Competition";
import { Standing } from "../../Models/Standing";
import { getFirestore } from "../../Utilities/firstore";
import { prepareForFirestore } from "../../Utilities/prepareForFirestore";

async function updateActivitySummaryScores(userID: string, before?: DocumentSnapshot, after?: DocumentSnapshot) {
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
            const beforeActivitySummary = new ActivitySummary(before);
            if (!beforeActivitySummary.isIncludedInCompetition(competition)) return;
            pointsDiff = -beforeActivitySummary.pointsFor(competition.scoringModel);
        } else if (before == null && after != undefined) { // created
            const afterActivitySummary = new ActivitySummary(after);
            if (!afterActivitySummary.isIncludedInCompetition(competition)) return;
            pointsDiff = afterActivitySummary.pointsFor(competition.scoringModel);
        } else if (before != null && after != null) { // updated
            const beforeActivitySummary = new ActivitySummary(before);
            const afterActivitySummary = new ActivitySummary(after);
            if (!beforeActivitySummary.isIncludedInCompetition(competition)) return;
            if (!afterActivitySummary.isIncludedInCompetition(competition)) return;
            pointsDiff = afterActivitySummary.pointsFor(competition.scoringModel) - beforeActivitySummary.pointsFor(competition.scoringModel);
        }
        standing.points += pointsDiff;

        await standingDoc.set(prepareForFirestore(standing));
        await competition.updateStandingRanks();
    });
}

export {
    updateActivitySummaryScores
};
