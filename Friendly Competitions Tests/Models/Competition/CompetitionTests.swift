import XCTest

@testable import Friendly_Competitions

final class CompetitionTests: XCTestCase {

    func testThatEquatableIsCorrect() {
        let idA = UUID()
        let idB = UUID()
        let competitionA = Competition(id: idA, name: "a")
        let competitionB = Competition(id: idB, name: "b")
        let competitionA2 = Competition(id: idA, name: "c")
        XCTAssertEqual(competitionA, competitionA2)
        XCTAssertNotEqual(competitionA, competitionB)
    }

    func testThatStartedIsCorrect() {
        var competition = Competition()
        competition.start = .distantPast
        XCTAssertTrue(competition.started)
        competition.start = .distantFuture
        XCTAssertFalse(competition.started)
    }

    func testThatEndedIsCorrect() {
        var competition = Competition()
        competition.end = .distantPast
        XCTAssertTrue(competition.ended)
        competition.end = .distantFuture
        XCTAssertFalse(competition.ended)
    }

    func testThatIsActiveIsCorrect() {
        var competition = Competition()

        competition.start = .distantPast
        competition.end = .distantFuture
        XCTAssertTrue(competition.isActive)

        competition.start = .distantFuture
        competition.end = .distantFuture
        XCTAssertFalse(competition.isActive)

        competition.start = .distantPast
        competition.end = .distantPast
        XCTAssertFalse(competition.isActive)
    }
}
