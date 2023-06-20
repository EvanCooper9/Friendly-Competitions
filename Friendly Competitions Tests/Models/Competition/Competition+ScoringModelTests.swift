import XCTest

@testable import Friendly_Competitions

class Competition_ScoringModelTests: FCTestCase {
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
}
