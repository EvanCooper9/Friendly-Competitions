import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import FCKitMocks
import HealthKit
import XCTest

@testable import FriendlyCompetitions

final class WorkoutManagerTests: FCTestCase {

    override func setUp() {
        super.setUp()
        userManager.user = .evan
        featureFlagManager.valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure = { flag in
            switch flag {
            case .dataUploadGracePeriodHours: return 12.0
            default: return 0.0
            }
        }
    }

    func testThatItRefetchesWhenCompetitionsChange() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(
            workoutQueryFetchResult: .success([HKWorkout(activityType: .walking, start: .now, end: .now.addingTimeInterval(1.hours))]),
            sampleQueryFetchResult: .success([.now: 1])
        )
        setupCached(workouts: [])
        setupDatabaseForUpload()

        let workoutManager = WorkoutManager()
        retainDuringTest(workoutManager)

        let scoringModel = Competition.ScoringModel.workout(.walking, [.distance]) 

        let competitionA = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: .now.addingTimeInterval(-1.days), end: .now.addingTimeInterval(1.days), repeats: true, isPublic: true, banner: nil)
        competitionsSubject.send([competitionA])
        let competitionB = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: .now.addingTimeInterval(-2.days), end: .now.addingTimeInterval(2.days), repeats: true, isPublic: true, banner: nil)
        competitionsSubject.send([competitionA, competitionB])

        XCTAssertEqual(healthKitManager.executeCallsCount, scoringModel.expectedHealthKitQueryCount * 3) // [competitionA], [competitionA, competitionB]
    }

    func testThatItDoesNotUploadDuplicates() {
        let competitionsSubject = PassthroughSubject<[Competition], Never>()
        competitionsManager.competitions = competitionsSubject.eraseToAnyPublisher()
        setupHealthKit(
            workoutQueryFetchResult: .success([HKWorkout(activityType: .walking, start: .now, end: .now.addingTimeInterval(1.hours))]),
            sampleQueryFetchResult: .success([.now: 1])
        )
        setupCached(workouts: [])

        let workoutDocument = DocumentMock<Workout>()
        database.documentDocumentPathStringDocumentClosure = { _ in workoutDocument }

        var seenWorkouts = Set<Workout>()
        let batch = BatchMock<Workout>()
        batch.setClosure = { workout, _ in
            seenWorkouts.insert(workout)
            self.setupCached(workouts: Array(seenWorkouts))
        }
        batch.commitClosure = { .just(()) }
        database.batchBatchReturnValue = batch

        let workoutManager = WorkoutManager()
        retainDuringTest(workoutManager)

        let scoringModel = Competition.ScoringModel.workout(.walking, [.distance])

        let competitionA = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: .now.addingTimeInterval(-1.days), end: .now.addingTimeInterval(1.days), repeats: true, isPublic: true, banner: nil)
        competitionsSubject.send([competitionA])

        let competitionB = Competition(name: #function, owner: "owner", participants: [], pendingParticipants: [], scoringModel: scoringModel, start: .now.addingTimeInterval(-2.days), end: .now.addingTimeInterval(2.days), repeats: true, isPublic: true, banner: nil)
        competitionsSubject.send([competitionA, competitionB])

        XCTAssertEqual(batch.setCallCount, seenWorkouts.count)
    }

    // MARK: - Private

    private func setupHealthKit(workoutQueryFetchResult: Result<[HKWorkout], Error>?, sampleQueryFetchResult: Result<[Date: Double], Error>?) {
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.executeClosure = { query in
            if let query = query as? WorkoutQuery {
                query.resultsHandler(workoutQueryFetchResult!)
            } else if let query = query as? SampleQuery {
                query.resultsHandler(sampleQueryFetchResult!)
            } else {
                XCTFail("Unexpected query type")
            }
        }
    }

    private func setupCached(workouts: [Workout]) {
        let cachedWorkoutCollection = CollectionMock<Workout>()
        cachedWorkoutCollection.getDocumentsClosure = { _, source in
            XCTAssertEqual(source, .cache)
            return .just(workouts)
        }

        database.collectionCollectionPathStringCollectionClosure = { path in
            XCTAssertEqual(path, "users/\(self.userManager.user.id)/workouts")
            return cachedWorkoutCollection
        }
    }

    private func setupDatabaseForUpload() {
        let workoutDocument = DocumentMock<Workout>()
        database.documentDocumentPathStringDocumentClosure = { _ in workoutDocument }

        let batch = BatchMock<Workout>()
        batch.setClosure = { _, _ in }
        batch.commitClosure = { .just(()) }
        database.batchBatchReturnValue = batch
    }
}

private extension Competition.ScoringModel {
    var expectedHealthKitQueryCount: Int {
        switch self {
        case .activityRingCloseCount, .percentOfGoals, .rawNumbers, .stepCount:
            return 1
        case .workout(_, let metrics):
            return metrics.count + 1
        }
    }
}
