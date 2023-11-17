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
        XCTAssertEqual(deepLink, .competitionResult(id: "abc123", resultID: nil))
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
            DeepLink.competitionResult(id: #function, resultID: nil).url,
            URL(string: "https://friendly-competitions.app/competition/\(#function)")!
        )
        XCTAssertEqual(
            DeepLink.competitionResult(id: "abc", resultID: "123").url,
            URL(string: "https://friendly-competitions.app/competition/abc/results/123")!
        )
    }
}
