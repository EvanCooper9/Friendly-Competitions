import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import HealthKit
import XCTest

@testable import Friendly_Competitions

final class WorkoutManagerTests: FCTestCase {

    private var cache: WorkoutCacheMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var healthKitManager: HealthKitManagingMock!
    private var healthKitDataHelperBuilder: HealthKitDataHelperBuildingMock<[Workout]>!
    private var database: DatabaseMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!
    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()
        cache = .init()
        competitionsManager = .init()
        healthKitManager = .init()
        healthKitDataHelperBuilder = .init()
        database = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()

        container.competitionsManager.register { self.competitionsManager }
        container.healthKitManager.register { self.healthKitManager }
        container.healthKitDataHelperBuilder.register { self.healthKitDataHelperBuilder }
        container.database.register { self.database }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.userManager.register { self.userManager }
        container.workoutCache.register { self.cache }

        cancellables = .init()
        competitionsManager.competitions = .just([])
    }

    func testThatItDoesNotUploadDuplicates() {
        let expectation = self.expectation(description: #function)
        expectation.isInverted = true

        let expectedWorkouts = [Workout(type: .walking, date: .now, points: [.distance: 100])]

        userManager.user = .evan

        let batchMock = BatchMock<Workout>()
        batchMock.commitClosure = {
            if batchMock.commitCallCount > 1 {
                expectation.fulfill()
            }
        }
        batchMock.setClosure = { _, _ in }

        database.batchClosure = { batchMock }
        database.documentClosure = { _ in DocumentMock<ActivitySummary>() }

        let manager = WorkoutManager()

        let healthKitDataHelper = healthKitDataHelperBuilder.healthKitDataHelper!
        healthKitDataHelper.upload(data: expectedWorkouts)
            .flatMapLatest { healthKitDataHelper.upload(data: expectedWorkouts) }
            .sink()
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
        print(manager) // needed to retain workout manager
    }
}
