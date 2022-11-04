import XCTest

@testable import Friendly_Competitions

final class TimeIntervalTests: XCTestCase {
    func testThatSecondsIsCorrect() {
        XCTAssertEqual(1.0.seconds, 1)
        XCTAssertEqual(10.0.seconds, 10)
        XCTAssertEqual(100.0.seconds, 100)
    }

    func testThatMinutesIsCorrect() {
        XCTAssertEqual(1.0.minutes, 60)
        XCTAssertEqual(10.0.minutes, 600)
        XCTAssertEqual(100.0.minutes, 6000)
    }

    func testThatHoursIsCorrect() {
        XCTAssertEqual(1.0.hours, 3600)
        XCTAssertEqual(10.0.hours, 36000)
        XCTAssertEqual(100.0.hours, 360000)
    }

    func testThatDaysIsCorrect() {
        XCTAssertEqual(1.0.days, 86400)
        XCTAssertEqual(10.0.days, 864000)
        XCTAssertEqual(100.0.days, 8640000)
    }
}
