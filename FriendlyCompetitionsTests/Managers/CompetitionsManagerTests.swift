import Combine
import ECKit
import Factory
import FCKitMocks
import XCTest

@testable import FriendlyCompetitions

final class CompetitionsManagerTests: FCTestCase {

    override func setUp() {
        super.setUp()
        userManager.user = .evan
        appState.didBecomeActive = .never()
        environmentManager.environment = .debugLocal
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
        collection.filterOnClosure = { _, _ in collection }
        collection.getDocumentsClosure = { _, _ in .never() }

        database.collectionCollectionPathStringCollectionReturnValue = collection

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
        database.documentDocumentPathStringDocumentClosure = { id in
            XCTAssertEqual(id, "competitions/\(competition.id)")
            return document
        }

        setupDatabaseWithCompetitions()
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
        database.documentDocumentPathStringDocumentClosure = { id in
            XCTAssertEqual(id, "competitions/\(competition.id)")
            return document
        }

        setupDatabaseWithCompetitions()
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
        competitionsCollection.filterOnClosure = { _, _ in competitionsCollection }
        competitionsCollection.getDocumentsClosure = { _, _ in .never() }

        let resultsCollection = CollectionMock<CompetitionResult>()
        resultsCollection.filterOnClosure = { _, _ in resultsCollection }
        resultsCollection.getDocumentsClosure = { _, _ in .never() }

        database.collectionCollectionPathStringCollectionClosure = { path in
            if path.hasSuffix("results") {
                return resultsCollection
            } else {
                return competitionsCollection
            }
        }

        userManager.user = .evan
    }
}
