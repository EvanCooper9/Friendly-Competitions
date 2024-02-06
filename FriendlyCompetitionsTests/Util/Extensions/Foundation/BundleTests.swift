import Foundation
import XCTest

@testable import Friendly_Competitions

final class BundleTests: FCTestCase {
    func testThatNameIsCorrect() {
        XCTAssertEqual(Bundle.main.name, "Friendly Competitions")
    }
}
