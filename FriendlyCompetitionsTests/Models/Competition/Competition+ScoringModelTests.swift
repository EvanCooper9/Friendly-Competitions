import XCTest

@testable import FriendlyCompetitions

class Competition_ScoringModelTests: FCTestCase {
    func testThatIdIsCorrect() {
        [Competition.ScoringModel.percentOfGoals, .rawNumbers, .workout(.walking, [])].forEach { scoringModel in
            XCTAssertEqual(scoringModel.id, scoringModel.displayName)
        }
    }

    func testThatDisplayNameIsCorrect() {
        XCTAssertEqual(Competition.ScoringModel.activityRingCloseCount.displayName, L10n.Competition.ScoringModel.ActivityRingCloseCount.displayName)
        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.displayName, L10n.Competition.ScoringModel.PercentOfGoals.displayName)
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.displayName, L10n.Competition.ScoringModel.RawNumbers.displayName)
        XCTAssertEqual(Competition.ScoringModel.stepCount.displayName, L10n.Competition.ScoringModel.Steps.displayName)
        XCTAssertEqual(Competition.ScoringModel.workout(.walking, []).displayName, L10n.Competition.ScoringModel.Workout.displayNameWithType(WorkoutType.walking.description))
    }

    func testThatDescriptionIsCorrect() {
        XCTAssertEqual(Competition.ScoringModel.activityRingCloseCount.description, L10n.Competition.ScoringModel.ActivityRingCloseCount.description)
        XCTAssertEqual(Competition.ScoringModel.percentOfGoals.description, L10n.Competition.ScoringModel.PercentOfGoals.description)
        XCTAssertEqual(Competition.ScoringModel.rawNumbers.description, L10n.Competition.ScoringModel.RawNumbers.description)
        XCTAssertEqual(Competition.ScoringModel.stepCount.description, L10n.Competition.ScoringModel.Steps.description)
        XCTAssertEqual(Competition.ScoringModel.workout(.walking, []).description, L10n.Competition.ScoringModel.Workout.descriptionWithType(WorkoutType.walking.description))
    }
}
