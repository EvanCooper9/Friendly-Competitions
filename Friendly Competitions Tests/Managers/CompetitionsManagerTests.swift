import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class CompetitionsManagerTests: FCTestCase {
    
    private var api: APIMock!
    private var appState: AppStateProvidingMock!
    private var analyticsManager: AnalyticsManagingMock!
    private var cache: CompetitionCacheMock!
    private var database: DatabaseMock!
    private var userManager: UserManagingMock!
    
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        api = .init()
        appState = .init()
        analyticsManager = .init()
        cache = .init()
        database = .init()
        userManager = .init()
        
        container.api.register { self.api }
        container.appState.register { self.appState }
        container.analyticsManager.register { self.analyticsManager }
        container.competitionCache.register { self.cache }
        container.database.register { self.database }
        container.userManager.register { self.userManager }
        cancellables = .init()
        
        appState.didBecomeActive = .never()
    }
    
    func testThatItFetchesAndUpdatesCompetitions() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3
        
        let expectedCompetitions: [[Competition]] = [
            [.mock],
            [.mockFuture],
            [.mockPublic]
        ]
        
        let competitionSourcesSubjects = (1...3).map { _ in
            PassthroughSubject<[Competition], Error>()
        }
        
        let collection = CollectionMock<Competition>()
        collection.publisherClosure = {
            return competitionSourcesSubjects[collection.publisherCallCount - 1].eraseToAnyPublisher()
        }
        collection.whereFieldArrayContainsClosure = { collection }
        collection.whereFieldIsEqualToClosure = { collection }
        collection.getDocumentsClosure = { _, _ in .never() }
        
        database.collectionReturnValue = collection
        
        let user = User.evan
        userManager.user = user
        
        let didBecomeActive = PassthroughSubject<Bool, Never>()
        appState.didBecomeActive = didBecomeActive.eraseToAnyPublisher()
        
        let manager = CompetitionsManager()
        manager.competitions
            .expect(expectedCompetitions[0], expectation: expectation)
            .store(in: &cancellables)

        manager.invitedCompetitions
            .expect(expectedCompetitions[1], expectation: expectation)
            .store(in: &cancellables)
        
        manager.appOwnedCompetitions
            .expect(expectedCompetitions[2], expectation: expectation)
            .store(in: &cancellables)
        
        // trigger app state didBecomeActive
        didBecomeActive.send(true)
        
        // trigger update
        competitionSourcesSubjects.enumerated().forEach { index, subject in
            subject.send(expectedCompetitions[index])
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItDoesNotFetchCompetitionsUnlessActive() {
        
        let collection = CollectionMock<Competition>()
        collection.publisherClosure = {
            XCTFail("Should not be called")
            return .never()
        }
        database.collectionClosure = { id in
            collection
        }
        
        let manager = CompetitionsManager()
        manager.competitions
            .sink()
            .store(in: &cancellables)
    }
    
    func testThatCreateSucceeds() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        let competition = Competition.mock
        
        let document = DocumentMock<Competition>()
        document.setClosure = { data in
            XCTAssertEqual(data, competition)
            expectation.fulfill()
            return .just(())
        }
        database.documentClosure = { id in
            XCTAssertEqual(id, "competitions/\(competition.id)")
            return document
        }
        
        let manager = CompetitionsManager()
        
        testAPI(manager.create(competition), expect: .success(()), expectation: expectation)
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatCreateFails() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        let error = MockError.mock(id: #function)
        let competition = Competition.mock
        
        let document = DocumentMock<Competition>()
        document.setClosure = { data in
            XCTAssertEqual(data, competition)
            expectation.fulfill()
            return .error(error)
        }
        database.documentClosure = { id in
            XCTAssertEqual(id, "competitions/\(competition.id)")
            return document
        }
        
        let manager = CompetitionsManager()
        
        testAPI(manager.create(competition), expect: .failure(error), expectation: expectation)
        
        waitForExpectations(timeout: 1)
    }
    
    // MARK: - Private
    
    private func testAPI(_ publisher: AnyPublisher<Void, Error>, expect expectedResult: Result<Void, MockError>, expectation: XCTestExpectation) {
        publisher
            .mapToResult()
            .sink { result in
                switch (result, expectedResult) {
                case (.success, .success):
                    expectation.fulfill()
                case (.failure(let error), .failure(let expectedError)):
                    guard let error = error as? MockError else {
                        XCTFail("Wrong error type")
                        return
                    }
                    XCTAssertEqual(error, expectedError)
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupDatabaseWithCompetitions(participating: [Competition] = [.mock], invited: [Competition] = [.mockInvited], appOwned: [Competition] = [.mockPublic]) {
        let expectedCompetitions: [[Competition]] = [
            participating,
            invited,
            appOwned
        ]
        
        let competitionSourcesSubjects = (0...2).map { i in
            CurrentValueSubject<[Competition], Error>(expectedCompetitions[i])
        }
        
        let competitionsCollection = CollectionMock<Competition>()
        competitionsCollection.publisherClosure = {
            return competitionSourcesSubjects[competitionsCollection.publisherCallCount - 1].eraseToAnyPublisher()
        }
        competitionsCollection.whereFieldArrayContainsClosure = { competitionsCollection }
        competitionsCollection.whereFieldIsEqualToClosure = { competitionsCollection }
        competitionsCollection.getDocumentsClosure = { _, _ in .never() }

        let resultsCollection = CollectionMock<CompetitionResult>()
        resultsCollection.whereFieldArrayContainsClosure = { resultsCollection }
        resultsCollection.getDocumentsClosure = { _, _ in .never() }

        database.collectionClosure = { path in
            if path.hasSuffix("results") {
                return resultsCollection
            } else {
                return competitionsCollection
            }
        }
        
        userManager.user = .evan
    }
}
