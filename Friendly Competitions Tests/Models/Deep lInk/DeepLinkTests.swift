import XCTest

@testable import Friendly_Competitions

final class DeepLinkTests: FCTestCase {
    func testThatFriendReferralCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/user/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .user(id: "abc123"))
    }

    func testThatCompetitionCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/competition/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .competition(id: "abc123"))
    }
    
    func testThatCompetitionResultsCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/competition/abc123/results")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .competitionResults(id: "abc123"))
    }
    
    func testThatUrlIsCorrect() {
        XCTAssertEqual(
            DeepLink.user(id: #function).url,
            URL(string: "https://friendly-competitions.app/user/\(#function)")!
        )
        XCTAssertEqual(
            DeepLink.competition(id: #function).url,
            URL(string: "https://friendly-competitions.app/competition/\(#function)")!
        )
        XCTAssertEqual(
            DeepLink.competitionResults(id: #function).url,
            URL(string: "https://friendly-competitions.app/competition/\(#function)/results")!
        )
    }
}
