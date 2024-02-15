import XCTest

@testable import FriendlyCompetitions

final class WorkoutTypeTests: FCTestCase {
    func testThatIdIsCorrect() {
        WorkoutType.allCases.forEach { workoutType in
            XCTAssertEqual(workoutType.id, workoutType.rawValue)
        }
    }
    
    func testThatInitIsCorrect() {
        XCTAssertEqual(WorkoutType(hkWorkoutActivityType: .cycling), .cycling)
        XCTAssertEqual(WorkoutType(hkWorkoutActivityType: .running), .running)
        XCTAssertEqual(WorkoutType(hkWorkoutActivityType: .swimming), .swimming)
        XCTAssertEqual(WorkoutType(hkWorkoutActivityType: .walking), .walking)
    }
    
    func testThatHKWorkoutActivityTypeIsCorrect() {
        XCTAssertEqual(WorkoutType.cycling.hkWorkoutActivityType, .cycling)
        XCTAssertEqual(WorkoutType.running.hkWorkoutActivityType, .running)
        XCTAssertEqual(WorkoutType.swimming.hkWorkoutActivityType, .swimming)
        XCTAssertEqual(WorkoutType.walking.hkWorkoutActivityType, .walking)
    }
}
