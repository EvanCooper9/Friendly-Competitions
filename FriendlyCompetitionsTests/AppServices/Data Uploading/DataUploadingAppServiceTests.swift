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
}
