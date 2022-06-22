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
        let key = UserDefaults.Key.activitySummary
        let expected = Model(foo: 1, bar: "a")
        userDefaults.encode(expected, forKey: key)
        let data = userDefaults.data(forKey: key.rawValue)!
        let actual = try Model.decoded(from: data)
        XCTAssertEqual(expected, actual)
    }

    func testThatDecodeWorks() throws {
        let key = UserDefaults.Key.activitySummary
        let expected = Model(foo: 1, bar: "a")
        let data = try JSONEncoder.shared.encode(expected)
        userDefaults.set(data, forKey: key.rawValue)
        let actual = userDefaults.decode(Model.self, forKey: key)
        XCTAssertEqual(expected, actual)
    }
}
