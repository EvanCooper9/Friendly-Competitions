import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class RootViewModelTests: XCTestCase {

    private var competitionsManager: CompetitionsManagingMock!
    private var friendsManager: FriendsManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()
        competitionsManager = .init()
        friendsManager = .init()
        cancellables = .init()
        
        Container.competitionsManager.register { self.competitionsManager }
        Container.friendsManager.register { self.friendsManager }
    }

    override func tearDown() {
        competitionsManager = nil
        friendsManager = nil
        cancellables = nil
        super.tearDown()
    }

    func testThatCompetitionInviteURLIsHandled() {
        let expectation = expectation(description: #function)

        let competition = Competition.mock
        competitionsManager.searchByIDReturnValue = .just(competition)

        let viewModel = RootViewModel()
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

        let viewModel = RootViewModel()
        viewModel.$deepLinkedUser
            .expect(nil, user, expectation: expectation)
            .store(in: &cancellables)

        viewModel.handle(url: DeepLink.friendReferral(id: user.id).url)
        waitForExpectations(timeout: 1)
    }
}
