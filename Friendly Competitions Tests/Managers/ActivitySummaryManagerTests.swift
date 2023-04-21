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
    private var healthKitManager: HealthKitManagingMock!
    private var healthKitDataHelperBuilder: HealthKitDataHelperBuildingMock<[ActivitySummary]>!
    private var database: DatabaseMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!

    private var cancellables: Cancellables!

    private var manager: ActivitySummaryManager!
    
    override func setUp() {
        super.setUp()
        cache = .init()
        healthKitManager = .init()
        healthKitDataHelperBuilder = .init()
        database = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()

        container.activitySummaryCache.register { self.cache }
        container.healthKitManager.register { self.healthKitManager }
        container.healthKitDataHelperBuilder.register { self.healthKitDataHelperBuilder }
        container.database.register { self.database }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.userManager.register { self.userManager }
        cancellables = .init()
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
                return strongSelf.healthKitDataHelperBuilder.healthKitDataHelper!.upload(data: activitySummaries)
            }
            .sink()
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }

    func testThatItDoesNotUploadDuplicates() {
        let expectation = self.expectation(description: #function)

        userManager.user = .evan

        let activitySummaryA = ActivitySummary.mock.with(userID: userManager.user.id)
        let activitySummaryB = ActivitySummary.mock.with(userID: userManager.user.id).with(date: .now.addingTimeInterval(1.days))

        let firstActivitySummaries = [activitySummaryA]
        let secondActivitySummaries = [activitySummaryA, activitySummaryB]

        expectation.expectedFulfillmentCount = 2 + (firstActivitySummaries + secondActivitySummaries).uniqued(on: \.id).count

        let firstBatch = BatchMock<ActivitySummary>()
        firstBatch.commitClosure = expectation.fulfill
        firstBatch.setClosure = { activitySummary, _ in
            XCTAssertEqual(activitySummary, firstActivitySummaries[firstBatch.setCallCount - 1])
            expectation.fulfill()
        }

        let secondBatch = BatchMock<ActivitySummary>()
        secondBatch.commitClosure = expectation.fulfill
        secondBatch.setClosure = { activitySummary, _ in
            let expectedActivitySummariesForUpload = secondActivitySummaries.filter { activitySummary in
                !firstActivitySummaries.contains(activitySummary)
            }
            XCTAssertEqual(activitySummary, expectedActivitySummariesForUpload[secondBatch.setCallCount - 1])
            expectation.fulfill()
        }

        database.documentReturnValue = DocumentMock<ActivitySummary>()
        database.batchClosure = {
            if self.database.batchCallsCount == 1 {
                return firstBatch
            } else if self.database.batchCallsCount == 2 {
                return secondBatch
            }
            XCTFail("Too many calls to batch")
            return BatchMock<ActivitySummary>()
        }

        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink() // needed to retain manager
            .store(in: &cancellables)

        let healthKitDataHelper = healthKitDataHelperBuilder.healthKitDataHelper!
        healthKitDataHelper.upload(data: firstActivitySummaries)
            .flatMapLatest { healthKitDataHelper.upload(data: secondActivitySummaries) }
            .sink()
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
}
