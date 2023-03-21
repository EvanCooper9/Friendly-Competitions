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
        
        Container.shared.api.register { self.api }
        Container.shared.appState.register { self.appState }
        Container.shared.analyticsManager.register { self.analyticsManager }
        Container.shared.competitionCache.register { self.cache }
        Container.shared.database.register { self.database }
        Container.shared.userManager.register { self.userManager }
        cancellables = .init()
        
        appState.didBecomeActive = .never()
    }
    
    override func tearDown() {
        super.tearDown()
        api = nil
        appState = nil
        analyticsManager = nil
        cache = .init()
        database = nil
        userManager = nil
        cancellables = nil
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
        collection.getDocumentsClosure = { .never() }
        
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
    
    func testThatAcceptSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
  
        testAPI(manager.accept(competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToCompetitionInvite")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, true)
        waitForExpectations(timeout: 1)
    }
    
    func testThatAcceptFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
        
        testAPI(manager.accept(competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToCompetitionInvite")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, true)
        waitForExpectations(timeout: 1)
    }
    
    func testThatCreateSucceeds() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        let competition = Competition.mock
        
        let document = DocumentMock<Competition>()
        document.setDataClosure = { data in
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
        document.setDataClosure = { data in
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
    
    func testThatDeclineSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
  
        testAPI(manager.decline(competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToCompetitionInvite")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, false)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeclineFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
        
        testAPI(manager.decline(competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToCompetitionInvite")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, false)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeleteSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
  
        testAPI(manager.delete(competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "deleteCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeleteFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
        
        testAPI(manager.delete(competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "deleteCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatInviteSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let user = User.evan
        let manager = CompetitionsManager()
  
        testAPI(manager.invite(user, to: competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "inviteUserToCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatInviteFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let user = User.evan
        let manager = CompetitionsManager()
        
        testAPI(manager.invite(user, to: competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "inviteUserToCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatJoinSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
  
        testAPI(manager.join(competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "joinCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatJoinFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
        
        testAPI(manager.join(competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "joinCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatLeaveSucceeds() {
        let expectation = self.expectation(description: #function)
        api.callWithReturnValue = .just(())
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
  
        testAPI(manager.leave(competition), expect: .success(()), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "leaveCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatLeaveFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        
        let competition = Competition.mock
        let manager = CompetitionsManager()
        
        testAPI(manager.leave(competition), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "leaveCompetition")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["competitionID"] as? String, competition.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatCompetitionsDateIntervalIsCorrect() {
        let cachedDateInterval = DateInterval()
        cache.competitionsDateInterval = cachedDateInterval
        
        let didBecomeActive = PassthroughSubject<Bool, Never>()
        appState.didBecomeActive = didBecomeActive.eraseToAnyPublisher()
        
        let competitions = [Competition.mock]
        setupDatabaseWithCompetitions(participating: competitions)
        
        let manager = CompetitionsManager()
        XCTAssertEqual(manager.competitionsDateInterval, cachedDateInterval)
        didBecomeActive.send(true)
        XCTAssertEqual(manager.competitionsDateInterval, competitions.dateInterval)
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
        
        let collection = CollectionMock<Competition>()
        collection.publisherClosure = {
            return competitionSourcesSubjects[collection.publisherCallCount - 1].eraseToAnyPublisher()
        }
        collection.whereFieldArrayContainsClosure = { collection }
        collection.whereFieldIsEqualToClosure = { collection }
        collection.getDocumentsClosure = { .never() }
        
        database.collectionReturnValue = collection
        
        userManager.user = .evan
    }
}
