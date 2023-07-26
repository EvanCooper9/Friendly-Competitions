import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import HealthKit
import XCTest

@testable import Friendly_Competitions

final class ActivitySummaryManagerTests: FCTestCase {
    
    override func setUp() {
        super.setUp()
        userManager.user = .evan
    }
    
    func testThatItFetchesActivitySummariesAndSetsCurrentOnSuccess() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        let expected = [ActivitySummary.mock]

        competitionsManager.competitions = .just([])
        setupHealthKit(fetchResult: .success(expected))
        setupCached(activitySummaries: [])
        setupDatabaseForUpload()

        let manager = ActivitySummaryManager()
        manager.activitySummary
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

        competitionsManager.competitions = .just([])
        setupHealthKit(fetchResult: .failure(MockError.mock(id: #function)))
        setupCached(activitySummaries: [])
        setupDatabaseForUpload()

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

    func testThatItRefetchesWhenCompetitionsChange() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(fetchResult: .success([.mock]))
        setupCached(activitySummaries: [])
        setupDatabaseForUpload()

        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink()
            .store(in: &cancellables)

        competitionsSubject.send([])
        competitionsSubject.send([.mock])

        XCTAssertEqual(healthKitManager.executeCallsCount, 2)
    }

    func testThatItDoesNotUploadDuplicates() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()

        let activitySummary = ActivitySummary.mock
        setupHealthKit(fetchResult: .success([activitySummary]))
        setupCached(activitySummaries: [])

        let activitySummaryDocument = DocumentMock<ActivitySummary>()
        database.documentClosure = { _ in activitySummaryDocument }

        var seenActivitySummaries = Set<ActivitySummary>()
        let batch = BatchMock<ActivitySummary>()
        batch.setClosure = { activitySummary, _ in
            seenActivitySummaries.insert(activitySummary)
            self.setupCached(activitySummaries: Array(seenActivitySummaries))
        }
        batch.commitClosure = { .just(()) }
        database.batchReturnValue = batch

        let manager = ActivitySummaryManager()
        manager.activitySummary
            .sink()
            .store(in: &cancellables)

        competitionsSubject.send([])
        competitionsSubject.send([.mock])
        XCTAssertEqual(batch.setCallCount, seenActivitySummaries.count)
    }

    // MARK: - Private

    private func setupHealthKit(fetchResult: Result<[ActivitySummary], Error>) {
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.executeClosure = { query in
            guard let query = query as? ActivitySummaryQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(fetchResult)
        }
    }

    private func setupCached(activitySummaries: [ActivitySummary]) {
        let activitySummaries = activitySummaries.map { $0.with(userID: userManager.user.id) }
        
        let cachedActivitySummaryCollection = CollectionMock<ActivitySummary>()
        cachedActivitySummaryCollection.getDocumentsClosure = { _, source in
            XCTAssertEqual(source, .cache)
            return .just(activitySummaries)
        }

        database.collectionClosure = { path in
            XCTAssertEqual(path, "users/\(self.userManager.user.id)/activitySummaries")
            return cachedActivitySummaryCollection
        }
    }

    private func setupDatabaseForUpload() {
        let activitySummaryDocument = DocumentMock<ActivitySummary>()
        database.documentClosure = { _ in activitySummaryDocument }

        let batch = BatchMock<ActivitySummary>()
        batch.setClosure = { _, _ in }
        batch.commitClosure = { .just(()) }
        database.batchReturnValue = batch
    }
}
