@testable import FriendlyCompetitions
import XCTest

final class ArrayTests: FCTestCase {
    func testAllTrue() {
        XCTAssertFalse([false, true, false, true].allTrue())
        XCTAssertTrue([true, true].allTrue())
        XCTAssertTrue([true].allTrue())
        XCTAssertTrue([].allTrue())
    }

    func testAllFalse() {
        XCTAssertFalse([false, true, false, true].allFalse())
        XCTAssertTrue([false, false].allFalse())
        XCTAssertTrue([false].allFalse())
        XCTAssertTrue([].allFalse())
    }
}
