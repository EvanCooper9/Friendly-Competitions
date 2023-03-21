import XCTest

@testable import Friendly_Competitions

final class UserTests: FCTestCase {
    func testThatHashIdIsCorrect() {
        let user = User(
            id: "testing",
            email: "test@example.com",
            name: "Test User"
        )

        XCTAssertEqual(user.hashId, "#TEST")
    }
    
    func testThatVisiblityIsCorrect() {
        let user = User(id: "testUser", email: "test@example.com", name: "Test User", friends: ["personA"], showRealName: false)
        let personA = User(id: "personA", email: "test@example.com", name: "Person A")
        let personB = User(id: "personB", email: "test@example.com", name: "Person B")
        
        XCTAssertEqual(user.visibility(by: user), .visible)
        XCTAssertEqual(user.visibility(by: personA), .visible)
        XCTAssertEqual(user.visibility(by: personB), .hidden)
    }
}
