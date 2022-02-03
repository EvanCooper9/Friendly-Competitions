import XCTest

@testable import Friendly_Competitions

final class UserTests: XCTestCase {

    private let user = User(
        id: "testing",
        email: "test@example.com",
        name: "Test User"
    )

    func testThatHashIdIsCorrect() {
        XCTAssertEqual(user.hashId, "#TEST")
    }

    func testThatEquatableIsCorrect() {
        let userA = User(id: "a", email: "a", name: "a")
        let userB = User(id: "b", email: "b", name: "b")
        let userA2 = User(id: "a", email: "c", name: "c")
        XCTAssertEqual(userA, userA2)
        XCTAssertNotEqual(userA, userB)
    }
}
