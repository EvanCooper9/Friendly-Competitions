import Combine
@testable import FriendlyCompetitions
import XCTest

final class CompetitionDetailsViewModelTests: FCTestCase {
    func testThatCompetitionIsSet() {
        let competition = Competition.mock
        competitionsManager.competitionPublisherForReturnValue = .never()
        let viewModel = CompetitionDetailsViewModel(competition: competition)
        XCTAssertEqual(viewModel.competition, competition)
    }

    func testThatIsInvitationIsCorrect() {
        let competitionSubject = PassthroughSubject<Competition, Error>()
        competitionsManager.competitionPublisherForReturnValue = competitionSubject.eraseToAnyPublisher()
        userManager.user = .evan

        let competition = Competition.mock
        let viewModel = CompetitionDetailsViewModel(competition: competition)

        XCTAssertFalse(viewModel.isInvitation)
        competitionSubject.send(.mockInvited)
        XCTAssertTrue(viewModel.isInvitation)
    }
}
