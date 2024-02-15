import Foundation
import XCTest

@testable import FriendlyCompetitions

final class BundleTests: FCTestCase {
    func testThatNameIsCorrect() {
        XCTAssertEqual(Bundle.main.name, "Friendly Competitions")
    }
}
