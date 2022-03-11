import XCTest

@testable import Friendly_Competitions

final class DeepLinkTests: XCTestCase {
    func testThatFriendReferralCanBeInitialized() {
        let url = URL(string: "friendly-competitions.app/invite/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .friendReferral(id: "abc123"))
    }

    func testThatCompetitionInviteCanBeInitialized() {
        let url = URL(string: "friendly-competitions.app/competition/abc123")!
        let deepLink = DeepLink(from: url)
        XCTAssertEqual(deepLink, .friendReferral(id: "abc123"))
    }
}
