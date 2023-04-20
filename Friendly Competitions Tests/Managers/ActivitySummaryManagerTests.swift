import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import HealthKit
import XCTest

@testable import Friendly_Competitions

final class ActivitySummaryManagerTests: FCTestCase {
    
    private var cache: ActivitySummaryCacheMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var healthKitManager: HealthKitManagingMock!
    private var healthKitDataHelperBuilder: HealthKitDataHelperBuildingMock<[ActivitySummary]>!
    private var database: DatabaseMock!
    private var permissionsManager: PermissionsManagingMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!
    private var workoutManager: WorkoutManagingMock!
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        cache = .init()
        competitionsManager = .init()
        healthKitManager = .init()
        healthKitDataHelperBuilder = .init()
        database = .init()
        permissionsManager = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()
        workoutManager = .init()
        
        container.activitySummaryCache.register { self.cache }
        container.competitionsManager.register { self.competitionsManager }
        container.healthKitManager.register { self.healthKitManager }
        container.healthKitDataHelperBuilder.register { self.healthKitDataHelperBuilder }
        container.database.register { self.database }
        container.permissionsManager.register { self.permissionsManager }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.userManager.register { self.userManager }
        container.workoutManager.register { self.workoutManager }
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
            .sink { activitySummary in
                XCTAssertEqual(activitySummary, expected.first)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        manager.activitySummaries(in: .init())
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
        batchMock.setClosure = { activitySummary, document in
            let expectedActivitySummary = expected[batchMock.setCallCount - 1]
            XCTAssertEqual(activitySummary, expectedActivitySummary)
            expectation.fulfill()
        }
        
        database.batchClosure = { batchMock }
        database.documentClosure = { path in
            let expectedActivitySummary = expected[self.database.documentCallsCount - 1]
            XCTAssertEqual(path, "users/\(user.id)/activitySummaries/\(expectedActivitySummary.id)")
            return DocumentMock<ActivitySummary>()
        }
        
        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink()
            .store(in: &cancellables)

        healthKitDataHelperBuilder.healthKitDataHelper!
            .fetch(dateInterval: .init())
            .flatMapLatest(withUnretained: self) { strongSelf, activitySummaries in
                XCTAssertEqual(activitySummaries, expected)
                return strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.uplaod(data: activitySummaries)
            }
            .sink()
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }

    func testThatItDoesNotUploadDuplicates() {
        let expectation = self.expectation(description: #function)
        expectation.isInverted = true

        let expectedActivitySummaries = [ActivitySummary.mock]

        userManager.user = .evan

        healthKitManager.executeClosure = { query in
            guard let query = query as? ActivitySummaryQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(.success(expectedActivitySummaries))
        }

        let batchMock = BatchMock<ActivitySummary>()
        batchMock.commitClosure = {
            if batchMock.commitCallCount > 1 {
                expectation.fulfill()
                XCTFail("committing more than once")
            }
        }
        batchMock.setClosure = { _, _ in }

        database.batchClosure = { batchMock }
        database.documentClosure = { _ in DocumentMock<ActivitySummary>() }

        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink()
            .store(in: &cancellables)

        healthKitDataHelperBuilder.healthKitDataHelper!
            .fetch(dateInterval: .init())
            .flatMapLatest(withUnretained: self) { strongSelf, activitySummaries in
                XCTAssertEqual(activitySummaries, expectedActivitySummaries)
                return strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.uplaod(data: activitySummaries)
            }
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.fetch(dateInterval: .init())
            }
            .flatMapLatest(withUnretained: self) { strongSelf, activitySummaries in
                XCTAssertEqual(activitySummaries, expectedActivitySummaries)
                return strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.uplaod(data: activitySummaries)
            }
            .sink()
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
}
