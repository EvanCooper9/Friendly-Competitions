import XCTest

@testable import Friendly_Competitions

class Competition_ScoringModelTests: XCTestCase {
    func testThatIdIsCorrect() {
        [Competition.ScoringModel.percentOfGoals, .rawNumbers, .workout(.walking, [])].forEach { scoringModel in
            XCTAssertEqual(scoringModel.id, scoringModel.displayName)
        }
    }

    func testThatDisplayNameIsCorrect() {
        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.displayName, "Percent of Goals")
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.displayName, "Raw numbers")
        XCTAssertEqual(Competition.ScoringModel.workout(.walking, []).displayName, "Walking workout")
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
        XCTAssertEqual(
            Competition.ScoringModel.workout(.walking, []).description,
            "Only Walking workouts will count towards points."
        )
    }
}
