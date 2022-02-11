import XCTest

@testable import Friendly_Competitions

final class EncodableTests: XCTestCase {

    func testThatJsonDictionaryIsCorrect() throws {
        struct Model: Encodable {
            let foo: Int
            let bar: String
        }

        let model = Model(foo: 1, bar: "a")
        let expected: [String: Any] = ["foo": 1, "bar": "a"]
        let actual = try model.jsonDictionary()
        XCTAssertEqual(expected["foo"] as! Int, actual["foo"] as! Int)
        XCTAssertEqual(expected["bar"] as! String, actual["bar"] as! String)
    }

    func testThatEncodedIsCorrect() throws {
        let string = "Something to be encoded"
        let expected = try JSONEncoder.shared.encode(string)
        XCTAssertEqual(expected, try string.encoded())
    }
}
