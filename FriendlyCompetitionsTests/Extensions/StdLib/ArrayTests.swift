import XCTest

@testable import FriendlyCompetitions

final class ArrayTests: XCTestCase {
    func testThatAppendingIsCorrect() {
        let array = [0]
        XCTAssertEqual(array.appending(1), [0, 1])
    }

    func testThatAppendingContentsOfIsCorrect() {
        let array = [0]
        XCTAssertEqual(array.appending(contentsOf: []), [0])
        XCTAssertEqual(array.appending(contentsOf: [1]), [0, 1])
    }

    func testThatRemoveIsCorrect() {
        var array = [0]
        array.remove(1)
        XCTAssertEqual(array, [0])
        array.remove(0)
        XCTAssertEqual(array, [])
    }

    func testThatRemovingIsCorrect() {
        let array = [0]
        XCTAssertEqual(array.removing(0), [])
        XCTAssertEqual(array.removing(1), [0])
    }

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
