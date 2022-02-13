import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as notifications from "./notifications";
import * as moment from "moment";
admin.initializeApp();

const firestore = admin.firestore();

interface Standing {
    points: number;
    rank: number;
    userId: string;
}

/**
 * Returns true if the activity summary falls within the competition window
 * @param {number} activitySummaryDate 
 * @param {number} competitionStart 
 * @param {number} competitionEnd 
 * @return {boolean} True if the activity summary falls within the competition window
 */
function shouldComputeScore(activitySummaryDate: number, competitionStart: number, competitionEnd: number): boolean {
    return activitySummaryDate >= competitionStart && activitySummaryDate <= competitionEnd;
}

exports.sendIncomingFriendRequestNotification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async change => {
        const user = change.after.data();
        const newFriendRequests: string[] = user.incomingFriendRequests;
        const oldFriendRequests: string[] = change.before.data().incomingFriendRequests;

        if (newFriendRequests == oldFriendRequests) {
            return null;
        }

        const incomingFriends = newFriendRequests
            .filter((x: string) => !oldFriendRequests.includes(x))
            .map(incomingFriendId => {
                return admin.auth().getUser(incomingFriendId);    
            });

        return Promise.all(incomingFriends)
            .then(incomingFriends => {
                const notificationPromises = incomingFriends.map(incomingFriend => {
                    return notifications.sendNotifications(
                        user.id, 
                        "Friendly Competitions",
                        `${incomingFriend.displayName} added you as a friend`
                    );
                });
                return Promise.all(notificationPromises);
            });
    });

exports.updateCompetitionStandings = functions.https
    .onCall(async data => {
        const userId = data.userId;
        if (userId != "NqduqRO62IfW6RkTq6otUey9xv42") {
            return;
        }

        const competitionsRef = await firestore.collection("competitions").get();
        const updateCompetitions = competitionsRef.docs.map(async competitionDoc => {
            const competition = competitionDoc.data();
            if (!competition.participants.includes(userId)) {
                return null;
            }
                        
            const competitionStart = Date.parse(competition.start);
            const competitionEnd = Date.parse(competition.end);

            let totalPoints = 0;
            const activitySummariesRef = await firestore.collection(`users/${userId}/activitySummaries`).get();
            activitySummariesRef.docs.forEach(activitySummaryDoc => {
                const activitySummaryDate = Date.parse(activitySummaryDoc.id);

                if (!shouldComputeScore(activitySummaryDate, competitionStart, competitionEnd)) {
                    return;
                }
                
                const activitySummary = activitySummaryDoc.data();
                
                if (competition.scoringModel == 0) {
                    const energy = (activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal) * 100;
                    const exercise = (activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal) * 100;
                    const stand = (activitySummary.appleStandHours / activitySummary.appleStandHoursGoal) * 100;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                } else if (competition.scoringModel == 1) {
                    const energy = activitySummary.activeEnergyBurned;
                    const exercise = activitySummary.appleExerciseTime;
                    const stand = activitySummary.appleStandHours;
                    const points = energy + exercise + stand;
                    totalPoints += parseInt(`${points}`);
                }
            });

            const standingsRef = await firestore.collection(`competitions/${competition.id}/standings`).get();
            const standings = standingsRef.docs
                .map(standingDoc => {
                    const standing = standingDoc.data();
                    if (standing.userId == userId) {
                        standing.points = totalPoints;
                    }
                    return standing;
                });

            const existingStanding = standings.filter(standing => {
                return standing.userId == userId;
            });

            if (existingStanding == null) {
                const standing: Standing = {points: totalPoints, rank: 0, userId: userId}; 
                standings.push(standing);
            }

            const updateStandings = standings
                .sort((a, b) => {
                    if (a.points < b.points) {
                        return -1;
                    }
                    if (a.points > b.points) {
                        return 1;
                    }
                    return 0;
                })
                .reverse()
                .map((standing, index) => {
                    standing.rank = index + 1;
                    return firestore.doc(`competitions/${competition.id}/standings/${standing.userId}`).set(standing);
                });
            
            return Promise.all(updateStandings);
        });

        return Promise.all(updateCompetitions);
    });

exports.sendNewCompetitionNotification = functions.firestore
    .document("competitions/{competitionId}")
    .onCreate(async snapshot => {

        const competition = snapshot.data();
        const pendingParticipants: string[] = competition.pendingParticipants;
        const creatorId = competition.participants.filter((x: string) => !pendingParticipants.includes(x))[0];
        const creatorPromise = await firestore.doc(`users/${creatorId}`).get();
        const creator = creatorPromise.data();

        if (creator == null) {
            return;
        }

        const pendingParticipantPromises = pendingParticipants.map(pendingParticipant => {
            return firestore.doc(`users/${pendingParticipant}`).get();
        });

        return Promise.all(pendingParticipantPromises)
            .then(pendingParticipants => {
                
                if (pendingParticipants == null) {
                    return null;
                }

                const notificationPromises = pendingParticipants.map(pendingParticipant => {
                    const user = pendingParticipant.data();   
                    
                    if (user == null) {
                        return null;
                    }

                    return notifications.sendNotifications(
                        user.id,
                        "Friendly Competitions",
                        `${creator.name} invited you to a competition`
                    );
                });

                return Promise.all(notificationPromises);
            });
    });

exports.cleanStaleActivitySummaries = functions.pubsub.schedule("every day 02:00")
    .timeZone("America/Toronto")
    .onRun(async context => {
        const usersRef = await firestore.collection("users").get();
        const users = usersRef.docs.map(userDoc => {
            return userDoc.data();
        });

        const competitionsRef = await firestore.collection("competitions").get();
        const competitions = await competitionsRef.docs.map(competitionDoc => {
            return competitionDoc.data();
        });

        const cleanUsers = users
            .map(async user => {
                
                const participatingCompetitions = competitions.filter(competition => {
                    return competition.participants.includes(user.id);
                });

                const activitySummariesRef = await firestore.collection(`users/${user.id}/activitySummaries`).get();
                const activitySummariesToDelete = activitySummariesRef.docs
                    .filter(activitySummaryDoc => {
                        const activitySummaryDate = Date.parse(activitySummaryDoc.id);
                        const matchingCompetition = participatingCompetitions.find(competition => {
                            const competitionStart = Date.parse(competition.start);
                            const competitionEnd = Date.parse(competition.end);
                            return shouldComputeScore(activitySummaryDate, competitionStart, competitionEnd);
                        });
                        return matchingCompetition == null || matchingCompetition == undefined;
                    })
                    .map(activitySummaryDoc => {
                        return firestore.doc(`users/${user.id}/activitySummaries/${activitySummaryDoc.id}`).delete();
                    });

                return Promise.all(activitySummariesToDelete);
            });
        
        return Promise.all(cleanUsers);
    });

exports.sendCompetitionCompleteNotifications = functions.pubsub.schedule("every day 12:00")
    .timeZone("America/Toronto")
    .onRun(async context => {
        const yesterday = moment().utc().subtract(1, "day");
        
        const competitionsRef = await firestore.collection("competitions").get();

        const competitionPromises = competitionsRef.docs.map(async competitionDoc => {
            const competition = competitionDoc.data();
            const competitionEnd = moment(competition.end);

            if (yesterday.dayOfYear() != competitionEnd.dayOfYear() || yesterday.year() != competitionEnd.year()) {
                return;
            }

            const standingsRef = await firestore.collection(`competitions/${competition.id}/standings`).get();
            const standings = standingsRef.docs.map(doc => {
                return doc.data();
            });

            /**
             * Returns a ordinal representation for a given number
             * @param {number} n number to get ordinal string for
             * @return {string} ordinal representation of number
             */
            function nth(n: number) {
                return ["st", "nd", "rd"][((n+90)%100-10)%10-1] || "th";
            }

            const notificationPromises = competition.participants.map(async (participantId: string) => {
                const standing = standings.find(standing => {
                    return standing.userId == participantId;
                });

                if (standing == null) {
                    return null;
                }

                const rank = standing.rank;

                const promises: Promise<void>[] = [];
                if (rank >=1 && rank <= 3) {
                    const userRef = await firestore.doc(`users/${participantId}`).get();
                    const user = userRef.data();
                    if (user != null) {
                        let statistics = user.statistics;
                        if (statistics == null) {
                            statistics = {golds: 0, silvers: 0, bronzes: 0};
                        }
                        if (rank == 1) {
                            statistics.golds += 1;
                        } else if (rank == 2) {
                            statistics.silvers += 1;
                        } else if (rank == 3) {
                            statistics.bronzes += 1;
                        }
                        user.statistics = statistics;
                        const updateUser = firestore.doc(`users/${participantId}`)
                            .set(user)
                            .then(user => {
                                return; 
                            });
                        promises.push(updateUser);
                    }
                }

                const nfs = notifications.sendNotifications(
                    participantId,
                    "Competition complete!",
                    `You placed ${rank}${nth(rank)} in ${competition.name}!`
                );
                promises.push(nfs);
                
                return Promise.all(promises);
            });

            return Promise.all(notificationPromises);
        });

        return Promise.all(competitionPromises);
    });
