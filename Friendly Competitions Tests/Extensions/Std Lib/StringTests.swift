import XCTest

@testable import Friendly_Competitions

final class StringTests: XCTestCase {
    func testThatAfterWorks() {
        let string = "abc123"
        XCTAssertEqual(string.after(prefix: "a"), "bc123")
        XCTAssertEqual(string.after(prefix: "ab"), "c123")
        XCTAssertEqual(string.after(prefix: "abc"), "123")
        XCTAssertNil(string.after(prefix: "abcd"))
        XCTAssertNil(string.after(prefix: "123"))
    }

    func testThatBeforeWorks() {
        let string = "abc123"
        XCTAssertEqual(string.before(suffix: "3"), "abc12")
        XCTAssertEqual(string.before(suffix: "23"), "abc1")
        XCTAssertEqual(string.before(suffix: "123"), "abc")
        XCTAssertNil(string.before(suffix: "1234"))
        XCTAssertNil(string.before(suffix: "abc"))
    }
}
