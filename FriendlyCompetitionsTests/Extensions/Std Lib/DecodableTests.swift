import XCTest

@testable import Friendly_Competitions

final class DecodableTests: XCTestCase {
    func testThatDecodedIsCorrect() throws {
        struct Model: Codable, Equatable {
            let foo: Int
            let bar: String
        }

        let model = Model(foo: 1, bar: "a")
        let data = try model.encoded()
        XCTAssertEqual(model, try Model.decoded(from: data))
    }
}
