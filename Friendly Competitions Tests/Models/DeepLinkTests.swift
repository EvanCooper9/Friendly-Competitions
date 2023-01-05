import XCTest

@testable import Friendly_Competitions

final class DeepLinkTests: XCTestCase {
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
    
    func testThatCompetitionHistoryCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/competition/abc123/history")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .competitionHistory(id: "abc123"))
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
            DeepLink.competitionHistory(id: #function).url,
            URL(string: "https://friendly-competitions.app/competition/\(#function)/history")!
        )
    }
}
