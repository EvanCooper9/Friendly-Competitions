import XCTest

@testable import Friendly_Competitions

final class DatabaseTests: FCTestCase {

    func testThatItEncodesDatesProperly() {
        struct Model: Codable {
            let date: Date
            let optionalDate: Date
        }


    }
}
