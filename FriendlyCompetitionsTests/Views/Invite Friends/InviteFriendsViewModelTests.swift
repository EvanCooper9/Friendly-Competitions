import Combine
@testable import FriendlyCompetitions
import XCTest

final class InviteFriendsViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()
        competitionsManager.competitionPublisherForReturnValue = .never()
        friendsManager.friends = .just([])
        searchManager.searchForUsersByNameReturnValue = .never()
        userManager.userPublisher = .never()
    }

    func testThatSearchIsMade() {
        let expectedQuery = #function
        let viewModel = InviteFriendsViewModel(action: .addFriend)
        viewModel.searchText = expectedQuery
        scheduler.advance(by: 1)
        XCTAssertEqual(searchManager.searchForUsersByNameReceivedName, expectedQuery)
    }

    func testThatRowsAreCorrectForFriendInvite() {
        let currentUser = User.evan
        let searchResultUser = User.andrew
        userManager.userPublisher = .just(currentUser)
        searchManager.searchForUsersByNameReturnValue = .just([searchResultUser])

        let viewModel = InviteFriendsViewModel(action: .addFriend)
        viewModel.searchText = "evan"
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }
        XCTAssertEqual(row.id, searchResultUser.id)
        XCTAssertEqual(row.name, searchResultUser.name)
        XCTAssertEqual(row.pillId, searchResultUser.hashId)
        XCTAssertEqual(row.buttonTitle, "Invite")
    }

    func testThatRowsAreCorrectForCompetitionInvite() {
        let searchResultUser = User.andrew
        let competition = Competition(id: "id", name: "test", owner: "abc", participants: [], pendingParticipants: [], scoringModel: .percentOfGoals, start: .now, end: .now, repeats: true, isPublic: true, banner: nil)
        competitionsManager.competitionPublisherForReturnValue = .just(competition)
        searchManager.searchForUsersByNameReturnValue = .just([searchResultUser])

        let viewModel = InviteFriendsViewModel(action: .competitionInvite(competition))
        viewModel.searchText = "evan"
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }
        XCTAssertEqual(row.id, searchResultUser.id)
        XCTAssertEqual(row.name, searchResultUser.name)
        XCTAssertEqual(row.pillId, searchResultUser.hashId)
        XCTAssertEqual(row.buttonTitle, "Invite")
        XCTAssertFalse(row.buttonDisabled)
    }

    func testThatFriendsAreInitiallyShownForCompetitionInvie() {
        let currentUser = User.evan
        userManager.userPublisher = .just(currentUser)
        
        let friend = User.andrew
        friendsManager.friends = .just([friend])

        let competition = Competition(id: "id", name: "test", owner: "abc", participants: [], pendingParticipants: [], scoringModel: .percentOfGoals, start: .now, end: .now, repeats: true, isPublic: true, banner: nil)
        competitionsManager.competitionPublisherForReturnValue = .just(competition)
        
        let viewModel = InviteFriendsViewModel(action: .competitionInvite(competition))
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }
        XCTAssertEqual(viewModel.rows.count, 1)
        XCTAssertEqual(row.id, friend.id)
        XCTAssertEqual(row.name, friend.name)
    }

    func testThatInvitedFriendsAreInitiallyShownForCompetitionInvie() {
        let currentUser = User.evan
        userManager.userPublisher = .just(currentUser)

        let friend = User.andrew
        friendsManager.friends = .just([friend])

        let competition = Competition(id: "id", name: "test", owner: "abc", participants: [], pendingParticipants: [friend.id], scoringModel: .percentOfGoals, start: .now, end: .now, repeats: true, isPublic: true, banner: nil)
        competitionsManager.competitionPublisherForReturnValue = .just(competition)

        let viewModel = InviteFriendsViewModel(action: .competitionInvite(competition))
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }
        XCTAssertEqual(viewModel.rows.count, 1)
        XCTAssertEqual(row.id, friend.id)
        XCTAssertEqual(row.name, friend.name)
        XCTAssertEqual(row.buttonTitle, "Invited")
        XCTAssertTrue(row.buttonDisabled)
    }

    func testThatParticipatingFriendsAreInitiallyShownForCompetitionInvie() {
        let currentUser = User.evan
        userManager.userPublisher = .just(currentUser)

        let friend = User.andrew
        friendsManager.friends = .just([friend])

        let competition = Competition(id: "id", name: "test", owner: "abc", participants: [friend.id], pendingParticipants: [], scoringModel: .percentOfGoals, start: .now, end: .now, repeats: true, isPublic: true, banner: nil)
        competitionsManager.competitionPublisherForReturnValue = .just(competition)

        let viewModel = InviteFriendsViewModel(action: .competitionInvite(competition))
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }
        XCTAssertEqual(viewModel.rows.count, 1)
        XCTAssertEqual(row.id, friend.id)
        XCTAssertEqual(row.name, friend.name)
        XCTAssertEqual(row.buttonTitle, "Invited")
        XCTAssertTrue(row.buttonDisabled)
    }

    func testThatUserIsAddedAsFriend() {
        let currentUser = User.evan
        let searchResultUser = User.andrew
        userManager.userPublisher = .just(currentUser)
        searchManager.searchForUsersByNameReturnValue = .just([searchResultUser])
        api.callReturnValue = .just(())

        let viewModel = InviteFriendsViewModel(action: .addFriend)
        viewModel.searchText = "evan"
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }

        row.buttonAction()
        XCTAssertEqual(api.callReceivedEndpoint, .sendFriendRequest(id: searchResultUser.id))
    }

    func testThatUserIsInvitedToCompetition() {
        let searchResultUser = User.andrew
        let competition = Competition(id: "id", name: "test", owner: "abc", participants: [], pendingParticipants: [], scoringModel: .percentOfGoals, start: .now, end: .now, repeats: true, isPublic: true, banner: nil)
        competitionsManager.competitionPublisherForReturnValue = .just(competition)
        searchManager.searchForUsersByNameReturnValue = .just([searchResultUser])
        api.callReturnValue = .just(())

        let viewModel = InviteFriendsViewModel(action: .competitionInvite(competition))
        viewModel.searchText = "evan"
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }

        row.buttonAction()
        XCTAssertEqual(api.callReceivedEndpoint, .inviteUserToCompetition(competitionID: competition.id, userID: searchResultUser.id))
    }

    func testAcceptFriendRequest() {
        var currentUser = User.evan
        let searchResultUser = User.andrew
        currentUser.incomingFriendRequests = [searchResultUser.id]

        userManager.userPublisher = .just(currentUser)
        searchManager.searchForUsersByNameReturnValue = .just([searchResultUser])
        api.callReturnValue = .just(())

        let viewModel = InviteFriendsViewModel(action: .addFriend)
        viewModel.searchText = "andrew"
        scheduler.advance(by: 1)

        guard let row = viewModel.rows.first else {
            XCTFail("Empty rows, should not happen")
            return
        }

        row.buttonAction()
        XCTAssertEqual(api.callReceivedEndpoint, .respondToFriendRequest(from: searchResultUser.id, accept: true))
    }

    func testThatLoadingIsCorrect() {
        let expectation = expectation(description: #function)
        userManager.userPublisher = .just(.evan)

        let viewModel = InviteFriendsViewModel(action: .addFriend)
        viewModel.$loading
            .expect(false, true, true, false, expectation: expectation)
            .store(in: &cancellables)

        searchManager.searchForUsersByNameReturnValue = .just([.andrew])
        viewModel.searchText = "abc"
        scheduler.advance(by: 0.5) // debounce search text
        scheduler.advance() // receive on main queue

        waitForExpectations(timeout: 1)
    }

    func testThatShowEmptyIsCorrect() {
        userManager.userPublisher = .just(.evan)

        let viewModel = InviteFriendsViewModel(action: .addFriend)
        XCTAssertFalse(viewModel.showEmpty)

        searchManager.searchForUsersByNameReturnValue = .just([.andrew])
        viewModel.searchText = "abc"
        scheduler.advance(by: 0.5) // debounce search text
        scheduler.advance() // receive on main queue
        XCTAssertFalse(viewModel.showEmpty)

        searchManager.searchForUsersByNameReturnValue = .just([])
        viewModel.searchText = "abcd"
        scheduler.advance(by: 0.5) // debounce search text
        scheduler.advance() // receive on main queue
        XCTAssertTrue(viewModel.showEmpty)

        viewModel.searchText = ""
        scheduler.advance(by: 0.5) // debounce search text
        scheduler.advance() // receive on main queue
        XCTAssertFalse(viewModel.showEmpty)
    }
}
