import Combine
import XCTest

extension XCTestCase {
    func waitUntil<T: Equatable>(
        _ propertyPublisher: Published<T>.Publisher,
        equals expectedValue: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(
            description: "Awaiting value \(expectedValue)"
        )

        var cancellable: AnyCancellable?

        cancellable = propertyPublisher
            .dropFirst()
            .first(where: { $0 == expectedValue })
            .sink { value in
                XCTAssertEqual(value, expectedValue, file: file, line: line)
                cancellable?.cancel()
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
