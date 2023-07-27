import Factory
import XCTest

@testable import Friendly_Competitions

final class NewCompetitionViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()

        friendsManager.friends = .never()
        userManager.userPublisher = .never()
    }

    func testThatItCreatesACompetitionProperly() {

        let expectedStart = Date.now
        let expectedEnd = Date.now

        let document = DocumentMock<Competition>()
        document.setClosure = { competition in
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
