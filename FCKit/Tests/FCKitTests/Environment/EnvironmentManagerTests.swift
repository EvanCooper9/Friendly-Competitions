import Combine
import ECKit
import FCKitMocks
import XCTest

@testable import FCKit

final class EnvironmentManagerTests: XCTestCase {

    private let environmentCache = EnvironmentCacheMock()
    private var cancellables = Cancellables()

    func testThatItStartsWithCorrectValueWhenCacheSet() {
        let environment = FCEnvironment.debugRemote(destination: #function)
        environmentCache.environment = environment
        let environmentManager = EnvironmentManager()
        XCTAssertEqual(environmentManager.environment, environment)
    }

    func testThatItPublishesValues() {
        let expectation = self.expectation(description: #function)
        let expected = [FCEnvironment.prod, .debugLocal, .debugRemote(destination: #function)]
        let environmentManager = EnvironmentManager()

        environmentManager.environmentPublisher
            .dropFirst()
            .collect(expected.count)
            .sink { values in
                XCTAssertEqual(values, expected)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        expected.forEach { environment in
            environmentManager.set(environment)
        }

        waitForExpectations(timeout: 1)
    }

    func testThatTheCurrentValueIsCorrect() {
        let expected = [FCEnvironment.prod, .debugLocal, .debugRemote(destination: #function)]
        let environmentManager = EnvironmentManager()

        expected.forEach { environment in
            environmentManager.set(environment)
            XCTAssertEqual(environmentManager.environment, environment)
        }
    }
}
