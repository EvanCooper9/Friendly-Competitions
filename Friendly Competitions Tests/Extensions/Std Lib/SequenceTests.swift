import XCTest

@testable import Friendly_Competitions

final class SequenceTests: XCTestCase {
    func testThatSortedIsCorrect() {
        struct Sortable {
            let foo: Int
            let bar: String
        }

        let sortables: [Sortable] = [
            .init(foo: 1, bar: "c"),
            .init(foo: 2, bar: "b"),
            .init(foo: 3, bar: "a")
        ]

        let sortedOnFoo = sortables.sorted(by: \.foo)
        let sortedOnBar = sortables.sorted(by: \.bar)

        XCTAssertEqual(sortedOnFoo.map(\.foo), [1, 2, 3])
        XCTAssertEqual(sortedOnBar.map(\.bar), ["a", "b", "c"])
    }
}
