import XCTest

@testable import Friendly_Competitions

final class HomeViewModelTests: XCTestCase {

    private var competitionsManager: CompetitionsManagingMock!
    private var friendsManager: FriendsManagingMock!

    override func setUp() {
        competitionsManager = .init()
        friendsManager = .init()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        competitionsManager = nil
        friendsManager = nil
    }

    func testThatCompetitionInviteURLIsHandled() {
        competitionsManager.searchByIDReturnValue = .just(.mock)
        let viewModel = makeViewModel()
        viewModel.handle(url: DeepLink.competitionInvite(id: #function).url)
        XCTAssertEqual(viewModel.deepLinkedCompetition, nil)
    }
    
    func testThatFriendInviteURLIsHandled() {
        friendsManager.userWithIdReturnValue = .just(.evan)
        let viewModel = makeViewModel()
        viewModel.handle(url: DeepLink.friendReferral(id: #function).url)
        XCTAssertEqual(viewModel.deepLinkedUser, nil)
    }

    // MARK: - Private Methods

    private func makeViewModel() -> HomeViewModel {
        .init(competitionsManager: competitionsManager, friendsManager: friendsManager)
    }
}
