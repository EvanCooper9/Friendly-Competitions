import Combine
import ECKit
import XCTest

@testable import Friendly_Competitions

final class HealthKitManagerTests: FCTestCase {

    private var healthStore: HealthStoringMock!
    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()

        healthStore = .init()
        container.healthStore.register { self.healthStore }

        cancellables = .init()

        healthStore.shouldRequestReturnValue = .never()
    }

    func testThatShouldRequestIsCorrect() {
        let expectation = self.expectation(description: #function)
        let expected: [(HealthKitPermissionType, Bool)] = [(.activitySummaryType, false), (.workoutType, true)]
        expectation.expectedFulfillmentCount = expected.count

        let manager = HealthKitManager()
        expected.forEach { expectedPermission, expectedValue in
            healthStore.shouldRequestReturnValue = .just(expectedValue)
            manager.shouldRequest([expectedPermission])
                .expect(expectedValue, expectation: expectation)
                .store(in: &cancellables)
        }

        waitForExpectations(timeout: 1)
    }

    func testThatRequestIsCorrect() {
        let expectation = self.expectation(description: #function)
        let expected: [HealthKitPermissionType] = [.activitySummaryType, .workoutType]
        expectation.expectedFulfillmentCount = expected.count

        let manager = HealthKitManager()
        expected.forEach { expectedPermission in
            healthStore.requestReturnValue = .just(())
            manager.request([expectedPermission])
                .catch { error -> AnyPublisher<Void, Never> in
                    XCTFail(error.localizedDescription)
                    return .never()
                }
                .sink { expectation.fulfill() }
                .store(in: &cancellables)
        }

        waitForExpectations(timeout: 1)
    }
}
