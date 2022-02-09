import XCTest

@testable import Friendly_Competitions

class CompetitionStandingTests: XCTestCase {
    func testThatIdIsCorrect() {
        let standing = Competition.Standing(rank: 1, userId: #function, points: 10)
        XCTAssertEqual(standing.id, standing.userId)
        XCTAssertEqual(standing.id, #function)
    }
}
