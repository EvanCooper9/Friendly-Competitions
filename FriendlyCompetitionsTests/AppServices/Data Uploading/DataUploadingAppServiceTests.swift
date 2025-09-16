import Combine
import Factory
@testable import FriendlyCompetitions
import XCTest

final class DataUploadingAppServiceTests: FCTestCase {

    private let loggedInSubject = PassthroughSubject<Bool, Never>()

    override func setUp() {
        super.setUp()
        authenticationManager.loggedIn = loggedInSubject.eraseToAnyPublisher()
    }

    func testThatActivitySummaryManagerIsRetained() {
        weak var activitySummaryManager: ActivitySummaryManaging?
        Container.shared.activitySummaryManager.register {
            let manager = ActivitySummaryManagingMock()
            activitySummaryManager = manager
            return manager
        }

        let service = DataUploadingAppService()
        retainDuringTest(service)
        service.didFinishLaunching()

        // log in, retain manager
        loggedInSubject.send(true)
        XCTAssertNotNil(activitySummaryManager)

        // log out, release manager
        loggedInSubject.send(false)
        XCTAssertNil(activitySummaryManager)
    }

    func testThatStepCountManagerIsRetained() {
        weak var stepCountManager: StepCountManaging?
        Container.shared.stepCountManager.register {
            let manager = StepCountManagingMock()
            stepCountManager = manager
            return manager
        }

        let service = DataUploadingAppService()
        retainDuringTest(service)
        service.didFinishLaunching()

        // log in, retain manager
        loggedInSubject.send(true)
        XCTAssertNotNil(stepCountManager)

        // log out, release manager
        loggedInSubject.send(false)
        XCTAssertNil(stepCountManager)
    }

    func testThatWorkoutManagerIsRetained() {
        weak var workoutManager: WorkoutManaging?
        Container.shared.workoutManager.register {
            let manager = WorkoutManagingMock()
            workoutManager = manager
            return manager
        }

        let service = DataUploadingAppService()
        retainDuringTest(service)
        service.didFinishLaunching()

        // log in, retain manager
        loggedInSubject.send(true)
        XCTAssertNotNil(workoutManager)

        // log out, release manager
        loggedInSubject.send(false)
        XCTAssertNil(workoutManager)
    }

    func testThatManagersAreNotRecreatedOnRapidLoginStateChanges() {
        var managerCreationCount = 0
        Container.shared.activitySummaryManager.register {
            managerCreationCount += 1
            return ActivitySummaryManagingMock()
        }

        let service = DataUploadingAppService()
        retainDuringTest(service)
        service.didFinishLaunching()

        // Simulate rapid login state changes (as might happen during reauthentication)
        loggedInSubject.send(true)
        loggedInSubject.send(false)
        loggedInSubject.send(true)

        // Wait for debounce to settle
        let expectation = self.expectation(description: "debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Should only create manager once due to debouncing
        XCTAssertEqual(managerCreationCount, 1)
    }
}
