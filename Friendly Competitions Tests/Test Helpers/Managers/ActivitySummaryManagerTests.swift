import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import HealthKit
import XCTest

@testable import Friendly_Competitions

final class ActivitySummaryManagerTests: XCTestCase {
    
    private var cache: CacheMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var healthKitManager: HealthKitManagingMock!
    private var database: DatabaseMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!
    private var workoutManager: WorkoutManagingMock!
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        cache = .init()
        competitionsManager = .init()
        healthKitManager = .init()
        database = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()
        workoutManager = .init()
        
        Container.Registrations.reset()
        Container.cache.register { self.cache }
        Container.competitionsManager.register { self.competitionsManager }
        Container.healthKitManager.register { self.healthKitManager }
        Container.database.register { self.database }
        Container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        Container.userManager.register { self.userManager }
        Container.workoutManager.register { self.workoutManager }
        cancellables = .init()
        
        competitionsManager.competitions = .just([])
    }
    
    override func tearDown() {
        super.tearDown()
        cache = .init()
        competitionsManager = nil
        healthKitManager = nil
        database = nil
        scheduler = nil
        userManager = nil
        workoutManager = nil
        cancellables = nil
    }
    
    func testThatItFetchesActivitySummariesAndSetsCurrentOnSuccess() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        
        let expected = [ActivitySummary.mock]
        healthKitManager.executeClosure = { query in
            guard let query = query as? ActivitySummaryQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(.success(expected))
        }
        
        let manager = ActivitySummaryManager()
        manager.activitySummary
            .dropFirst()
            .print("activitySummary")
            .sink { activitySummary in
                XCTAssertEqual(activitySummary, expected.first)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        manager.activitySummaries(in: .init())
            .print("fetch")
            .ignoreFailure()
            .sink { activitySummaries in
                XCTAssertEqual(activitySummaries, expected)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        scheduler.advance()
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItSetsCurrentToNilOnFetchFailure() {
        let expectation = self.expectation(description: #function)
        
        healthKitManager.executeClosure = { query in
            guard let query = query as? ActivitySummaryQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(.failure(MockError.mock(id: #function)))
        }
        
        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink { activitySummary in
                XCTAssertNil(activitySummary)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        manager.activitySummaries(in: .init())
            .sink()
            .store(in: &cancellables)
        
        scheduler.advance()
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItUploadsCorrectly() {
        let expectation = self.expectation(description: #function)
        
        let user = User.evan
        userManager.user = user
        let expected = [
            ActivitySummary.mock.with(userID: user.id).with(date: .now.advanced(by: -2.days)),
            ActivitySummary.mock.with(userID: user.id).with(date: .now.advanced(by: -1.days)),
            ActivitySummary.mock.with(userID: user.id)
        ]
        expectation.expectedFulfillmentCount = expected.count + 1 // set each document + commit all
        
        healthKitManager.executeClosure = { query in
            guard let query = query as? ActivitySummaryQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(.success(expected))
        }
        
        let batchMock = BatchMock<ActivitySummary>()
        batchMock.commitClosure = expectation.fulfill
        batchMock.setDataClosure = { activitySummary, document in
            let expectedActivitySummary = expected[batchMock.setDataCallCount - 1]
            XCTAssertEqual(activitySummary, expectedActivitySummary)
            expectation.fulfill()
        }
        
        database.batchClosure = { batchMock }
        database.documentClosure = { path in
            let expectedActivitySummary = expected[self.database.documentCallsCount - 1]
            XCTAssertEqual(path, "users/\(user.id)/activitySummaries/\(expectedActivitySummary.id)")
            return DocumentMock<ActivitySummary>()
        }
        
        let competitions = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitions.share(replay: 1).eraseToAnyPublisher()
        competitionsManager.competitionsDateInterval = .init()
        
        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink()
            .store(in: &cancellables)
        
        // trigger fetch & upload
        competitions.send([.mock])
        scheduler.advance(by: .seconds(1))
        
        waitForExpectations(timeout: 1)
    }
}

extension ActivitySummary {
    func with(userID: User.ID) -> ActivitySummary {
        var activitySummary = self
        activitySummary.userID = userID
        return activitySummary
    }
    
    func with(date: Date) -> ActivitySummary {
        .init(
            activeEnergyBurned: activeEnergyBurned,
            appleExerciseTime: appleExerciseTime,
            appleStandHours: appleStandHours,
            activeEnergyBurnedGoal: activeEnergyBurnedGoal,
            appleExerciseTimeGoal: appleExerciseTimeGoal,
            appleStandHoursGoal: appleStandHoursGoal,
            date: date,
            userID: userID
        )
    }
}
