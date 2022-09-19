import XCTest

@testable import Friendly_Competitions

final class UserDefaultsTests: XCTestCase {

    private struct Model: Codable, Equatable {
        let foo: Int
        let bar: String
    }

    private var userDefaults: UserDefaults!

    override func setUp() {
        userDefaults = UserDefaults()
    }

    func testThatEncodeWorks() throws {
        let expected = Model(foo: 1, bar: "a")
        userDefaults.encode(expected, forKey: #function)
        let data = userDefaults.data(forKey: #function)!
        let actual = try Model.decoded(from: data)
        XCTAssertEqual(expected, actual)
    }

    func testThatDecodeWorks() throws {
        let expected = Model(foo: 1, bar: "a")
        let data = try JSONEncoder.shared.encode(expected)
        userDefaults.set(data, forKey: #function)
        let actual = userDefaults.decode(Model.self, forKey: #function)
        XCTAssertEqual(expected, actual)
    }
}
