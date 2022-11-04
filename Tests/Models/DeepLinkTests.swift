import XCTest

@testable import Friendly_Competitions

final class DeepLinkTests: XCTestCase {
    func testThatFriendReferralCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/friend/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .friendReferral(id: "abc123"))
    }

    func testThatCompetitionInviteCanBeInitialized() {
        let url = URL(string: "https://friendly-competitions.app/competition/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .competitionInvite(id: "abc123"))
    }
    
    func testThatUrlIsCorrect() {
        XCTAssertEqual(
            DeepLink.friendReferral(id: #function).url,
            URL(string: "https://friendly-competitions.app/friend/\(#function)")!
        )
        XCTAssertEqual(
            DeepLink.competitionInvite(id: #function).url,
            URL(string: "https://friendly-competitions.app/competition/\(#function)")!
        )
    }
}
