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

        let workoutA = Workout.mock()
        let workoutB = Workout.mock(date: .now.addingTimeInterval(1.days))

        let firstWorkouts = [workoutA]
        let secondWorkouts = [workoutA, workoutB]

        expectation.expectedFulfillmentCount = 2 + (firstWorkouts + secondWorkouts).uniqued(on: \.id).count

        userManager.user = .evan

        let firstBatch = BatchMock<Workout>()
        firstBatch.commitClosure = {
            expectation.fulfill()
            return .just(())
        }
        firstBatch.setClosure = { workout, _ in
            XCTAssertEqual(workout, firstWorkouts[firstBatch.setCallCount - 1])
            expectation.fulfill()
        }

        let secondBatch = BatchMock<Workout>()
        secondBatch.commitClosure = {
            expectation.fulfill()
            return .just(())
        }
        secondBatch.setClosure = { workout, _ in
            let expectedWorkoutsForUpload = secondWorkouts.filter { workout in
                !firstWorkouts.contains(workout)
            }
            XCTAssertEqual(workout, expectedWorkoutsForUpload[secondBatch.setCallCount - 1])
            expectation.fulfill()
        }

        database.documentReturnValue = DocumentMock<Workout>()
        database.batchClosure = {
            if self.database.batchCallsCount == 1 {
                return firstBatch
            } else if self.database.batchCallsCount == 2 {
                return secondBatch
            }
            XCTFail("Too many calls to batch")
            return BatchMock<Workout>()
        }

        let collection = CollectionMock<Workout>()
        collection.getDocumentsClosure = { _, _ in
            if collection.getDocumentsCallCount == 1 {
                return .just([])
            } else if collection.getDocumentsCallCount == 2 {
                return .just(firstWorkouts)
            }
            XCTFail("Too many calls to getDocuments")
            return .never()
        }
        database.collectionReturnValue = collection

        let manager = WorkoutManager()
        manager.workouts(of: .walking, with: [], in: .init())
            .sink() // needed to retain manager
            .store(in: &cancellables)

        let healthKitDataHelper = healthKitDataHelperBuilder.healthKitDataHelper!
        healthKitDataHelper.upload(data: firstWorkouts)
            .flatMapLatest { healthKitDataHelper.upload(data: secondWorkouts) }
            .sink()
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
}
