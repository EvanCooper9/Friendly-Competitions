import Factory
import XCTest

@testable import Friendly_Competitions

final class NewCompetitionViewModelTests: FCTestCase {

    private var database: DatabaseMock!
    private var friendsManager: FriendsManagingMock!
    private var userManager: UserManagingMock!

    override func setUp() {
        super.setUp()
        database = .init()
        friendsManager = .init()
        userManager = .init()

        container.database.register { self.database }
        container.friendsManager.register { self.friendsManager }
        container.userManager.register { self.userManager }

        friendsManager.friends = .never()
        userManager.userPublisher = .never()
    }

    func testThatItCreatesACompetitionProperly() {

        let expectedStart = Date.now
        let expectedEnd = Date.now

        let document = DocumentMock<Competition>()
        document.setDataClosure = { competition in
            XCTAssertEqual(competition.start, expectedStart)
            XCTAssertEqual(competition.end, expectedEnd)
            return .just(())
        }
        database.documentReturnValue = document

        let viewModel = NewCompetitionViewModel()
        viewModel.start = expectedStart
        viewModel.end = expectedEnd

        viewModel.create()
    }
}
