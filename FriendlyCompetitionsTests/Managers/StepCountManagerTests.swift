import Combine
import FCKitMocks
import XCTest

@testable import FriendlyCompetitions

final class StepCountManagerTests: FCTestCase {

    override func setUp() {
        super.setUp()
        userManager.user = .evan
        featureFlagManager.valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure = { flag in
            switch flag {
            case .dataUploadGracePeriodHours: return 12.0
            default: return 0.0
            }
        }
        featureFlagManager.valueForBoolFeatureFlagFeatureFlagBoolBoolClosure = { flag in
            switch flag {
            case .ignoreManuallyEnteredHealthKitData: return true
            case .adsEnabled: return true
            case .newResultsBannerEnabled: return true
            }
        }
    }

    func testThatItRefetchesWhenCompetitionsChange() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(fetchResult: .success(10))
        setupCached(stepCounts: [])
        setupDatabaseForUpload()

        let manager = StepCountManager()
        retainDuringTest(manager)

        let start = Calendar.current.startOfDay(for: .now.addingTimeInterval(-5.days))
        let end = start.addingTimeInterval(24.hours - 1.seconds)
        let competitionA = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: .stepCount, start: start, end: end.addingTimeInterval(7.days), repeats: true, isPublic: true, banner: nil)
        let competitionB = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: .stepCount, start: start, end: end.addingTimeInterval(8.days), repeats: true, isPublic: true, banner: nil)
        let expectedCompetitions = [
            [competitionA],
            [competitionA, competitionB]
        ]

        expectedCompetitions.forEach { competitions in
            competitionsSubject.send(competitions)
        }

        let expectedQueryCount = expectedCompetitions.reduce(0) { partialResult, competitions in
            let dateInterval = competitions.dateInterval!.combined(with: .dataFetchDefault)
            let maxDate = min(dateInterval.end, .now)
            let days = Calendar.current.dateComponents([.day], from: dateInterval.start, to: maxDate).day ?? 0
            return partialResult + days + 1
        }
        XCTAssertEqual(healthKitManager.executeCallsCount, expectedQueryCount)
    }

    func testThatItDoesNotUploadDuplicates() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(fetchResult: .success(10))
        setupCached(stepCounts: [])

        let stepCountDocument = DocumentMock<StepCount>()
        database.documentDocumentPathStringDocumentClosure = { _ in stepCountDocument }

        var seenStepCounts = Set<StepCount>()
        let batch = BatchMock<StepCount>()
        batch.setClosure = { stepCount, _ in
            seenStepCounts.insert(stepCount)
            self.setupCached(stepCounts: Array(seenStepCounts))
        }
        batch.commitClosure = { .just(()) }
        database.batchBatchReturnValue = batch

        let manager = StepCountManager()
        retainDuringTest(manager)

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

        database.collectionCollectionPathStringCollectionClosure = { path in
            XCTAssertEqual(path, "users/\(self.userManager.user.id)/steps")
            return cachedStepCountCollection
        }
    }

    private func setupDatabaseForUpload() {
        let stepCountDocument = DocumentMock<StepCount>()
        database.documentDocumentPathStringDocumentClosure = { _ in stepCountDocument }

        let batch = BatchMock<StepCount>()
        batch.setClosure = { _, _ in }
        batch.commitClosure = { .just(()) }
        database.batchBatchReturnValue = batch
    }
}
