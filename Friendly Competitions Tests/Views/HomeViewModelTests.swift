import XCTest

@testable import Friendly_Competitions

final class HomeViewModelTests: XCTestCase {
    func testThatCompetitionInviteURLIsHandled() {
        let viewModel = HomeViewModel()
        viewModel.handle(url: DeepLink.competitionInvite(id: #function).url)
        XCTAssertEqual(viewModel.deepLinkedCompetition, nil)
    }
    
    func testThatFriendInviteURLIsHandled() {
        let viewModel = HomeViewModel()
        viewModel.handle(url: DeepLink.friendReferral(id: #function).url)
        XCTAssertEqual(viewModel.deepLinkedUser, nil)
    }
}
