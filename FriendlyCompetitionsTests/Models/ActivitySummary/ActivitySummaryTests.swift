import XCTest

@testable import Friendly_Competitions

final class ActivitySummaryTests: FCTestCase {
    
    func testThatIDIsCorrect() {
        let now = Date.now
        let activitySummary = ActivitySummary(
            activeEnergyBurned: 1,
            appleExerciseTime: 1,
            appleStandHours: 1,
            activeEnergyBurnedGoal: 1,
            appleExerciseTimeGoal: 1,
            appleStandHoursGoal: 1,
            date: now
        )
        XCTAssertEqual(activitySummary.id, now.encodedToString(with: .dateDashed))
    }
    
    func testThatClosedIsCorrect() {
        let activitySummaryNotClosed = ActivitySummary(
            activeEnergyBurned: 1,
            appleExerciseTime: 1,
            appleStandHours: 1,
            activeEnergyBurnedGoal: 2,
            appleExerciseTimeGoal: 2,
            appleStandHoursGoal: 2,
            date: .now
        )
        XCTAssertFalse(activitySummaryNotClosed.closed)
        
        let activitySummaryClosed = ActivitySummary(
            activeEnergyBurned: 1,
            appleExerciseTime: 1,
            appleStandHours: 1,
            activeEnergyBurnedGoal: 1,
            appleExerciseTimeGoal: 1,
            appleStandHoursGoal: 1,
            date: .now
        )
        XCTAssertTrue(activitySummaryClosed.closed)
    }
    
    func testThatPointsIsCorrect() {
        let expected: [Competition.ScoringModel: Double] = [
            .activityRingCloseCount: 1,
            .percentOfGoals: 200,
            .rawNumbers: 15,
            .workout(.walking, [.distance]): 0
        ]
        
        expected.forEach { scoringModel, expectedScore in
            let activitySummary = ActivitySummary(
                activeEnergyBurned: 5,
                appleExerciseTime: 5,
                appleStandHours: 5,
                activeEnergyBurnedGoal: 5,
                appleExerciseTimeGoal: 10,
                appleStandHoursGoal: 10,
                date: .now
            )
            XCTAssertEqual(activitySummary.points(from: scoringModel), expectedScore)
        }
    }

    func testThatHealthKitActvitySummaryIsCorrect() {
        let activitySumamry = ActivitySummary.mock
        let hkActivitySummary = activitySumamry.hkActivitySummary
        XCTAssertEqual(activitySumamry.activeEnergyBurned, hkActivitySummary.activeEnergyBurned.doubleValue(for: .largeCalorie()))
        XCTAssertEqual(activitySumamry.appleExerciseTime, hkActivitySummary.appleExerciseTime.doubleValue(for: .minute()))
        XCTAssertEqual(activitySumamry.appleStandHours, hkActivitySummary.appleStandHours.doubleValue(for: .count()))
        XCTAssertEqual(activitySumamry.activeEnergyBurnedGoal, hkActivitySummary.activeEnergyBurnedGoal.doubleValue(for: .largeCalorie()))
        XCTAssertEqual(activitySumamry.appleExerciseTimeGoal, hkActivitySummary.appleExerciseTimeGoal.doubleValue(for: .minute()))
        XCTAssertEqual(activitySumamry.appleStandHoursGoal, hkActivitySummary.appleStandHoursGoal.doubleValue(for: .count()))
    }
}
