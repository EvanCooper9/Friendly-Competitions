import XCTest

@testable import Friendly_Competitions

final class CompetitionParticipantRowConfigTests: FCTestCase {

    func testThatPropertiesAreCorrectForBasicConfiguration() {
        let user = User.andrew
        let currentUser = User.evan
        let standing = Competition.Standing(rank: 1, userId: user.id, points: 100)
        let config = CompetitionParticipantRow.Config(
            user: user,
            currentUser: currentUser,
            standing: standing
        )

        XCTAssertEqual(config.id, user.id)
        XCTAssertEqual(config.rank, standing.rank.ordinalString)
        XCTAssertEqual(config.name, user.name)
        XCTAssertEqual(config.idPillText, user.hashId)
        XCTAssertEqual(config.blurred, false)
        XCTAssertEqual(config.points, standing.points)
        XCTAssertEqual(config.highlighted, false)
    }

    func testIsNotBlurred() {
        let user = User.andrew
        let currentUser = User.evan
        let standing = Competition.Standing(rank: 1, userId: user.id, points: 100)
        let config = CompetitionParticipantRow.Config(
            user: user,
            currentUser: currentUser,
            standing: standing
        )

        XCTAssertFalse(config.blurred)
    }

    func testIsBlurred() {
        var user = User.andrew
        user.showRealName = false // blur the name
        let currentUser = User.evan
        let standing = Competition.Standing(rank: 1, userId: user.id, points: 100)
        let config = CompetitionParticipantRow.Config(
            user: user,
            currentUser: currentUser,
            standing: standing
        )

        XCTAssertTrue(config.blurred)
    }

    func testIsNotBlurredForFriendWithHidenName() {
        var user = User.andrew
        user.showRealName = false // blur the name
        let currentUser = User.evan
        let standing = Competition.Standing(rank: 1, userId: user.id, points: 100)
        let config = CompetitionParticipantRow.Config(
            user: user.with(friends: [currentUser.id]),
            currentUser: currentUser.with(friends: [user.id]),
            standing: standing
        )

        XCTAssertFalse(config.blurred) // blurred is false because they are friends
    }

    func testIsTie() {
        let user = User.andrew
        let currentUser = User.evan
        let standing = Competition.Standing(rank: 1, userId: user.id, points: 100, isTie: true)
        let config = CompetitionParticipantRow.Config(
            user: user,
            currentUser: currentUser,
            standing: standing
        )

        XCTAssertEqual(config.rank, "T\(standing.rank)")
    }
}
