import Combine
import XCTest

@testable import Friendly_Competitions

final class HomeViewModelTests: XCTestCase {

    private var competitionsManager: CompetitionsManagingMock!
    private var friendsManager: FriendsManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        competitionsManager = .init()
        friendsManager = .init()
        cancellables = .init()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        competitionsManager = nil
        friendsManager = nil
        cancellables = nil
    }

    func testThatCompetitionInviteURLIsHandled() {
        let expectation = expectation(description: #function)

        let competition = Competition.mock
        competitionsManager.searchByIDReturnValue = .just(competition)

        let viewModel = makeViewModel()
        viewModel.$deepLinkedCompetition
            .expect(nil, competition, expectation: expectation)
            .store(in: &cancellables)

        viewModel.handle(url: DeepLink.competitionInvite(id: competition.id).url)
        waitForExpectations(timeout: 1)
    }
    
    func testThatFriendInviteURLIsHandled() {
        let expectation = expectation(description: #function)

        let user = User.evan
        friendsManager.userWithIdReturnValue = .just(user)

        let viewModel = makeViewModel()
        viewModel.$deepLinkedUser
            .expect(nil, user, expectation: expectation)
            .store(in: &cancellables)

        viewModel.handle(url: DeepLink.friendReferral(id: user.id).url)
        waitForExpectations(timeout: 1)
    }

    // MARK: - Private Methods

    private func makeViewModel() -> HomeViewModel {
        .init(competitionsManager: competitionsManager, friendsManager: friendsManager)
    }
}
