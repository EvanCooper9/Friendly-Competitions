import XCTest

@testable import Friendly_Competitions

class Competition_ScoringModelTests: XCTestCase {
    func testThatIdIsCorrect() {
        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.id, 0)
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.id, 1)
    }

    func testThatDisplayNameIsCorrect() {
        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.displayName, "Percent of Goals")
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.displayName, "Raw numbers")
    }

    func testThatDescriptionIsCorrect() {
        XCTAssertEqual(
            Competition.ScoringModel.percentOfGoals.description,
            "Every percent of an activity ring filled gains 1 point. Daily max of 600 points."
        )
        XCTAssertEqual(
            Competition.ScoringModel.rawNumbers.description,
            "Every calorie, minute and hour gains 1 point. No daily max."
        )
    }

    func testThatScoreIsCorrect() {
        let activitySummary = ActivitySummary(
            activeEnergyBurned: 1,
            appleExerciseTime: 2,
            appleStandHours: 3,
            activeEnergyBurnedGoal: 5,
            appleExerciseTimeGoal: 5,
            appleStandHoursGoal: 5,
            date: .now
        )

        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.score(for: activitySummary), 120)
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.score(for: activitySummary), 6)
    }
}
