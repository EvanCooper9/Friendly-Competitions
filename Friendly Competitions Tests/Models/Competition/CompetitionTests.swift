import XCTest

@testable import Friendly_Competitions

final class CompetitionTests: FCTestCase {
    func testThatStartedIsCorrect() {
        XCTAssertTrue(Competition(start: .distantPast).started)
        XCTAssertFalse(Competition(start: .distantFuture).started)
    }

    func testThatEndedIsCorrect() {
        XCTAssertTrue(Competition(end: .distantPast).ended)
        XCTAssertFalse(Competition(end: .distantFuture).ended)
    }

    func testThatIsActiveIsCorrect() {
        XCTAssertTrue(Competition(start: .distantPast, end: .distantFuture).isActive)
        XCTAssertFalse(Competition(start: .distantFuture, end: .distantFuture).isActive)
        XCTAssertFalse(Competition(start: .distantPast, end: .distantPast).isActive)
    }
}

private extension Competition {
    init(id: String = UUID().uuidString, start: Date = .now, end: Date = .now) {
        self.init(
            id: id,
            name: #function,
            owner: #function,
            participants: [],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: start,
            end: end,
            repeats: false,
            isPublic: false,
            banner: nil
        )
    }
}
