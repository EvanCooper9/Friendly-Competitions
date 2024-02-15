@testable import FriendlyCompetitions
import XCTest

final class NavigationDestinationTests: FCTestCase {
    func testThatIDIsCorrect() {
        let competition = Competition.mock
        XCTAssertEqual(NavigationDestination.competition(competition, nil).id, competition.id)

        let user = User.evan
        XCTAssertEqual(NavigationDestination.user(user).id, user.id)

        XCTAssertEqual(NavigationDestination.profile.id, "profile")
    }
}
