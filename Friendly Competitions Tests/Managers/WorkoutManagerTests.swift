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

        healthKitManager.executeClosure = { query in
            if let query = query as? WorkoutQuery {
                query.resultsHandler(.success([]))
            } else if let query = query as? SampleQuery {
                query.resultsHandler(.success([:]))
            }
        }

        let batchMock = BatchMock<Workout>()
        batchMock.commitClosure = {
            if batchMock.commitCallCount > 1 {
                expectation.fulfill()
                XCTFail("committing more than once")
            }
        }
        batchMock.setClosure = { _, _ in }

        database.batchClosure = { batchMock }
        database.documentClosure = { _ in DocumentMock<ActivitySummary>() }

        let manager = WorkoutManager()

        healthKitDataHelperBuilder.healthKitDataHelper!
            .fetch(dateInterval: .init())
            .flatMapLatest(withUnretained: self) { strongSelf, _ in
                // directly inject expectedWorkouts because setting up the health kit queries is too much work
                strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.uplaod(data: expectedWorkouts)
            }
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.fetch(dateInterval: .init())
            }
            .flatMapLatest(withUnretained: self) { strongSelf, _ in
                // directly inject expectedWorkouts because setting up the health kit queries is too much work
                strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.uplaod(data: expectedWorkouts)
            }
            .sink()
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
        print(manager) // needed to retain workout manager
    }
}
