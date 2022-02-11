import XCTest

@testable import Friendly_Competitions

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
}
