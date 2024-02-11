import Combine
@testable import Friendly_Competitions
import XCTest

final class ExploreViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()
        competitionsManager.appOwnedCompetitions = .never()
        featureFlagManager.valueForBoolReturnValue = false
    }

    func testThatAppOwnedCompetitionsIsCorrect() {
        let expectedCompetition = Competition.mock
        let appOwnedCompetitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.appOwnedCompetitions = appOwnedCompetitionsSubject.eraseToAnyPublisher()

        let viewModel = ExploreViewModel()

        appOwnedCompetitionsSubject.send([])
        XCTAssertEqual(viewModel.appOwnedCompetitions, [])
        appOwnedCompetitionsSubject.send([expectedCompetition])
        XCTAssertEqual(viewModel.appOwnedCompetitions, [expectedCompetition])
        appOwnedCompetitionsSubject.send([])
        XCTAssertEqual(viewModel.appOwnedCompetitions, [])
    }

    func testLoadingIsCorrect() {
        let expectation = expectation(description: #function)
        let expected = [false, true, false]

        searchManager.searchForCompetitionsByNameReturnValue = .just([])

        let viewModel = ExploreViewModel()
        viewModel.$loading
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.searchText = "competition"

        waitForExpectations(timeout: 1)
    }

    func testThatSearchResultsAreCorrect() {
        let expectedCompetition = Competition.mock
        searchManager.searchForCompetitionsByNameReturnValue = .just([expectedCompetition])
        let viewModel = ExploreViewModel()
        viewModel.searchText = "competition"
        scheduler.advance()
        XCTAssertEqual(viewModel.searchResults, [expectedCompetition])
    }
}
