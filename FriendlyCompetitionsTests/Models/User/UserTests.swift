import XCTest

@testable import FriendlyCompetitions

final class UserTests: FCTestCase {
    func testThatHashIdIsCorrect() {
        let user = User(
            id: "testing",
            name: "Test User", email: "test@example.com"
        )

        XCTAssertEqual(user.hashId, "#TEST")
    }
    
    func testThatVisiblityIsCorrect() {
        let user = User(id: "testUser", name: "Test User", email: "test@example.com", friends: ["personA"], showRealName: false)
        let personA = User(id: "personA", name: "Test User", email: "test@example.com")
        let personB = User(id: "personB", name: "Person A", email: "test@example.com")

        XCTAssertEqual(user.visibility(by: user), .visible)
        XCTAssertEqual(user.visibility(by: personA), .visible)
        XCTAssertEqual(user.visibility(by: personB), .hidden)
    }
}
