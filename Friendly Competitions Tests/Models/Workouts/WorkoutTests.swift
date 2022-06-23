import XCTest

@testable import Friendly_Competitions

final class WorkoutTests: XCTestCase {
    func testThatIdIsCorrect() {
        let date = Date.now
        let type = WorkoutType.running
        let workout = Workout(type: type, date: date, points: 1000)
        let expected = "\(DateFormatter.dateDashed.string(from: date))_\(type)"
        XCTAssertEqual(expected, workout.id)
    }
}
