import Combine
import XCTest

@testable import Friendly_Competitions

final class StepCountManagerTests: FCTestCase {

    override func setUp() {
        super.setUp()
        userManager.user = .evan
    }

    func testThatItRefetchesWhenCompetitionsChange() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(fetchResult: .success(10))
        setupCached(stepCounts: [])
        setupDatabaseForUpload()

        let manager = StepCountManager()
        print(manager)

        let scoringModel = Competition.ScoringModel.stepCount

        let start = Calendar.current.startOfDay(for: .now).addingTimeInterval(-5.days)
        let competitionA = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: start, end: .now.addingTimeInterval(1.days), repeats: true, isPublic: true, banner: nil)
        let competitionB = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: start, end: .now.addingTimeInterval(2.days), repeats: true, isPublic: true, banner: nil)
        let expectedCompetitions = [
            [competitionA],
            [competitionA, competitionB]
        ]

        expectedCompetitions.forEach { competitions in
            competitionsSubject.send(competitions)
        }

        let expectedQueryCount = expectedCompetitions.reduce(0) { partialResult, competitions in
            let dateInterval = competitions.dateInterval!
            let days = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day ?? 0
            return partialResult + days
        }
        XCTAssertEqual(healthKitManager.executeCallsCount, expectedQueryCount)
    }

    func testThatItDoesNotUploadDuplicates() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(fetchResult: .success(10))
        setupCached(stepCounts: [])

        let stepCountDocument = DocumentMock<StepCount>()
        database.documentClosure = { _ in stepCountDocument }

        var seenStepCounts = Set<StepCount>()
        let batch = BatchMock<StepCount>()
        batch.setClosure = { stepCount, _ in
            seenStepCounts.insert(stepCount)
            self.setupCached(stepCounts: Array(seenStepCounts))
        }
        batch.commitClosure = { .just(()) }
        database.batchReturnValue = batch

        let manager = StepCountManager()
        print(manager)

        let scoringModel = Competition.ScoringModel.stepCount

        let start = Calendar.current.startOfDay(for: .now).addingTimeInterval(-5.days)
        let competitionA = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: start, end: .now.addingTimeInterval(1.days), repeats: true, isPublic: true, banner: nil)
        let competitionB = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: start, end: .now.addingTimeInterval(2.days), repeats: true, isPublic: true, banner: nil)
        let expectedCompetitions = [
            [competitionA],
            [competitionA, competitionB]
        ]

        expectedCompetitions.forEach { competitions in
            competitionsSubject.send(competitions)
        }

        XCTAssertEqual(batch.setCallCount, seenStepCounts.count)
    }

    // MARK: - Private

    private func setupHealthKit(fetchResult: Result<Double, Error>) {
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.executeClosure = { query in
            guard let query = query as? StepsQuery else {
                XCTFail("Unexpected query type")
                return
            }
            query.resultsHandler(fetchResult)
        }
    }

    private func setupCached(stepCounts: [StepCount]) {
        let cachedStepCountCollection = CollectionMock<StepCount>()
        cachedStepCountCollection.getDocumentsClosure = { _, source in
            XCTAssertEqual(source, .cache)
            return .just(stepCounts)
        }

        database.collectionClosure = { path in
            XCTAssertEqual(path, "users/\(self.userManager.user.id)/steps")
            return cachedStepCountCollection
        }
    }

    private func setupDatabaseForUpload() {
        let stepCountDocument = DocumentMock<StepCount>()
        database.documentClosure = { _ in stepCountDocument }

        let batch = BatchMock<StepCount>()
        batch.setClosure = { _, _ in }
        batch.commitClosure = { .just(()) }
        database.batchReturnValue = batch
    }
}
