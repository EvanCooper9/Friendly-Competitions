import Foundation
import XCTest

@testable import Friendly_Competitions

final class BundleTests: XCTestCase {
    func testThatNameIsCorrect() {
        XCTAssertEqual(Bundle.main.name, "Friendly Competitions")
    }

    func testThatDisplayNameIsCorrect() {
        XCTAssertEqual(Bundle.main.displayName, "Competitions")
    }
}
