import SwiftUI
import XCTest

@testable import Friendly_Competitions

class PermissionStatusTests: FCTestCase {
    func testThatButtonTitleIsCorrect() {
        XCTAssertEqual(PermissionStatus.authorized.buttonTitle, "Allowed")
        XCTAssertEqual(PermissionStatus.denied.buttonTitle, "Denied")
        XCTAssertEqual(PermissionStatus.notDetermined.buttonTitle, "Allow")
        XCTAssertEqual(PermissionStatus.done.buttonTitle, "Done")
    }

    func testThatButtonColorIsCorrect() {
        XCTAssertEqual(PermissionStatus.authorized.buttonColor, .green)
        XCTAssertEqual(PermissionStatus.denied.buttonColor, .red)
        XCTAssertEqual(PermissionStatus.notDetermined.buttonColor, .blue)
        XCTAssertEqual(PermissionStatus.done.buttonColor, .gray)
    }
}
