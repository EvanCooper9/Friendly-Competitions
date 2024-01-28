import Combine
import ECKit
import HealthKit
import XCTest

@testable import Friendly_Competitions

final class HealthKitManagerTests: FCTestCase {

    override func setUp() {
        super.setUp()
        healthStore.shouldRequestReturnValue = .never()
    }

    func testThatItRegistersForBackgroundDelivery() {
        authenticationManager.loggedIn = .just(true)

        healthStore.enableBackgroundDeliveryForReturnValue = .just(true)
        healthStore.shouldRequestClosure = { permissions in
            guard permissions.first!.objectType as? HKSampleType != nil else { return .just(true) }
            return .just(false)
        }
        
        let manager = HealthKitManager()
        manager.registerForBackgroundDelivery()
        retainDuringTest(manager)
        
        let expectedCount = HealthKitPermissionType.allCases
            .compactMap { $0.objectType as? HKSampleType }
            .count
        
        XCTAssertEqual(healthStore.enableBackgroundDeliveryForCallsCount, expectedCount)
    }
    
    func testThatShouldRequestIsCorrect() {
        let expectation = self.expectation(description: #function)
        let expected: [(HealthKitPermissionType, Bool)] = [(.activitySummaryType, false), (.workoutType, true)]
        expectation.expectedFulfillmentCount = expected.count
        
        healthStore.enableBackgroundDeliveryForReturnValue = .just(true)
        
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
        
        healthStore.enableBackgroundDeliveryForReturnValue = .just(true)
        
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
