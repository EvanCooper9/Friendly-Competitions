import Combine
import ECKit
import Factory
import Firebase
import FirebaseFirestore
import HealthKit
import UIKit

// sourcery: AutoMockable
protocol WorkoutManaging {
    func workouts(of type: WorkoutType, with metrics: [WorkoutMetric], in dateInterval: DateInterval) -> AnyPublisher<[Workout], Error>
}

final class WorkoutManager: WorkoutManaging {

    private enum Constants {
        static var cachedWorkoutMetricsKey: String { #function }
    }

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.database) private var database
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.healthKitDataHelperBuilder) private var healthKitDataHelperBuilder
    @Injected(\.userManager) private var userManager
    @Injected(\.workoutCache) private var cache

    private var helper: (any HealthKitDataHelping<[Workout]>)!

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        helper = healthKitDataHelperBuilder.bulid { [weak self] dateInterval in
            guard let strongSelf = self else { return .just([]) }
            let publishers = strongSelf.cache.workoutMetrics.map { workoutType, metrics in
                strongSelf.workouts(of: workoutType, with: metrics, in: dateInterval)
            }
            return Publishers
                .ZipMany(publishers)
                .map { $0.reduce([], +) }
                .eraseToAnyPublisher()
        } upload: { [weak self] workouts in
            self?.upload(workouts: workouts) ?? .just(())
        }

        fetchWorkoutMetrics()
            .sink(withUnretained: self) { $0.cache.workoutMetrics = $1 }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func workouts(of type: WorkoutType, with metrics: [WorkoutMetric], in dateInterval: DateInterval) -> AnyPublisher<[Workout], Error> {
        .fromAsync { [weak self] in
            guard let strongSelf = self else { return [] }
            let points = try await strongSelf.requestWorkouts(ofType: type, metrics: metrics, during: dateInterval)
            var workouts = [Workout]()
            points.forEach { date, pointsBySampleType in

                let points = pointsBySampleType.compactMap { sampleType, points -> (WorkoutMetric, Int)? in
                    guard let metric = WorkoutMetric(from: sampleType.identifier) else { return nil }
                    return (metric, Int(points))
                }

                let workout = Workout(
                    type: type,
                    date: date,
                    points: Dictionary(uniqueKeysWithValues: points)
                )

                workouts.append(workout)
            }
            return workouts
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func upload(workouts: [Workout]) -> AnyPublisher<Void, Error> {
        let changedWorkouts = database
            .collection("users/\(userManager.user.id)/workouts")
            .getDocuments(ofType: Workout.self, source: .cache)
            .map { cached in
                workouts
                    .subtracting(cached)
                    .sorted(by: \.date)
            }

        return changedWorkouts
            .flatMapAsync { [weak self] workouts in
                guard let strongSelf = self else { return }
                let userID = strongSelf.userManager.user.id
                let batch = strongSelf.database.batch()
                try workouts.forEach { workout in
                    let document = strongSelf.database.document("users/\(userID)/workouts/\(workout.id)")
                    try batch.set(value: workout, forDocument: document)
                }
                try await batch.commit()
            }
            .eraseToAnyPublisher()
    }

    private func fetchWorkoutMetrics() -> AnyPublisher<[WorkoutType: [WorkoutMetric]], Never> {
        competitionsManager.competitions
            .map { competitions -> [WorkoutType: [WorkoutMetric]] in
                competitions.reduce(into: [WorkoutType: [WorkoutMetric]]()) { partialResult, competition in
                    guard case let .workout(workoutType, metrics) = competition.scoringModel else { return }
                    let metricsForWorkoutType = (partialResult[workoutType] ?? [])
                        .appending(contentsOf: metrics)
                        .uniqued()
                    partialResult[workoutType] = Array(metricsForWorkoutType)
                }
            }
            .eraseToAnyPublisher()
    }

    private func requestWorkouts() -> AnyPublisher<[Workout], Never> {
        competitionsManager.competitions
            .map { competitions -> ([WorkoutType: [WorkoutMetric]], DateInterval) in
                let workoutTypes = competitions
                    .reduce(into: [WorkoutType: [WorkoutMetric]]()) { partialResult, competition in
                        guard case let .workout(workoutType, metrics) = competition.scoringModel else { return }
                        let metricsForWorkoutType = (partialResult[workoutType] ?? [])
                            .appending(contentsOf: metrics)
                            .uniqued()
                        partialResult[workoutType] = Array(metricsForWorkoutType)
                    }

                let dateInterval = competitions
                    .filter { competition in
                        guard competition.isActive else { return false }
                        switch competition.scoringModel {
                        case .workout:
                            return true
                        default:
                            return false
                        }
                    }
                    .dateInterval

                return (workoutTypes, dateInterval)
            }
            .flatMapAsync { [weak self] workoutTypes, dateInterval in
                try await withThrowingTaskGroup(of: (WorkoutType, [Date: [HKQuantityType: Double]]).self) { group -> [Workout] in
                    workoutTypes.forEach { workoutType, workoutMetrics in
                        group.addTask { [weak self] in
                            guard let self = self else { return (workoutType, [:]) }
                            let points = try await self.requestWorkouts(ofType: workoutType, metrics: workoutMetrics, during: dateInterval)
                            return (workoutType, points)
                        }
                    }

                    var workouts = [Workout]()
                    for try await (workoutType, pointsByDateBySampleType) in group {
                        pointsByDateBySampleType.forEach { date, pointsBySampleType in

                            let points = pointsBySampleType.compactMap { sampleType, points -> (WorkoutMetric, Int)? in
                                guard let metric = WorkoutMetric(from: sampleType.identifier) else { return nil }
                                return (metric, Int(points))
                            }
                            let workout = Workout(
                                type: workoutType,
                                date: date,
                                points: Dictionary(uniqueKeysWithValues: points)
                            )
                            workouts.append(workout)
                        }
                    }
                    return workouts
                }
            }
            .ignoreFailure()
    }

    private func requestWorkouts(ofType workoutType: WorkoutType, metrics: [WorkoutMetric], during dateInterval: DateInterval) async throws -> [Date: [HKQuantityType: Double]] {
        let predicate = HKQuery.predicateForWorkouts(with: workoutType.hkWorkoutActivityType)
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = WorkoutQuery(predicate: predicate, dateInterval: dateInterval) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let workouts):
                    continuation.resume(returning: workouts)
                }
            }
            healthKitManager.execute(query)
        }

        return try await withThrowingTaskGroup(of: [Date: [HKQuantityType: Double]].self) { group -> [Date: [HKQuantityType: Double]] in
            workouts.forEach { workout in
                group.addTask { [weak self] in
                    guard let self = self else { return [:] }
                    return try await self.pointsByDateByMetric(for: workout, metrics: metrics)
                }
            }

            var toReturn = [Date: [HKQuantityType: Double]]()
            for try await pointsByDateBySample in group {

                for (date, pointsBySampleType) in pointsByDateBySample {
                    guard let existing = toReturn[date] else {
                        toReturn[date] = pointsBySampleType
                        continue
                    }

                    toReturn[date] = pointsBySampleType
                        .enumerated()
                        .reduce(into: existing) { partialResult, next in
                            let (offset, (sampleType, points)) = next
                            switch WorkoutMetric(from: sampleType.identifier) {
                            case .heartRate:
                                let oldAverage = partialResult[sampleType] ?? 0
                                let oldTotal = oldAverage * Double(offset)
                                let newTotal = oldTotal + points
                                let newAverage = newTotal / Double(offset + 1)
                                partialResult[sampleType] = newAverage
                            case .distance, .steps, .none:
                                partialResult[sampleType] = (partialResult[sampleType] ?? 0) + points
                            }
                        }
                }
            }
            return toReturn
        }
    }

    /// Get the total points by date for all sample types of a given workout
    /// - Parameter workout: The workout to fetch the points for
    /// - Parameter metrics: The metrics to fetch points for
    /// - Throws: Any errors from  HealthKit
    /// - Returns: Points by date by sample type
    private func pointsByDateByMetric(for workout: HKWorkout, metrics: [WorkoutMetric]) async throws -> [Date: [HKQuantityType: Double]] {
        try await withThrowingTaskGroup(of: (HKQuantityType, [Date: Double]).self) { [weak self] group -> [Date: [HKQuantityType: Double]] in
            guard let self = self, let workoutType = WorkoutType(hkWorkoutActivityType: workout.workoutActivityType) else { return [:] }

            metrics
                .compactMap { metric -> (HKQuantityType, WorkoutMetric)? in
                    guard let sample = metric.sample(for: workoutType) else { return nil }
                    return (sample, metric)
                }
                .forEach { sample, metric in
                    group.addTask { [weak self] in
                        guard let self = self else { return (sample, [:]) }

                        let pointsByDate: [Date: Double]
                        switch metric {
                        case .steps:
                            // Steps are not actually recorded in workouts. A separate type of query is required
                            pointsByDate = try await self.steps(for: workout)
                        default:
                            pointsByDate = try await self.pointsByDate(sampleType: sample, workout: workout, unit: metric.unit)
                        }
                        return (sample, pointsByDate)
                    }
                }

            var toReturn = [String: [HKQuantityType: Double]]()
            for try await (sampleType, pointsByDate) in group {
                for (date, points) in pointsByDate {
                    let dateString = DateFormatter.dateDashed.string(from: date)
                    let result = [sampleType: points]
                    guard var pointsBySampleType = toReturn[dateString] else {
                        toReturn[dateString] = result
                        continue
                    }
                    pointsBySampleType[sampleType] = (pointsBySampleType[sampleType] ?? 0) + points
                    toReturn[dateString] = pointsBySampleType
                }
            }

            return toReturn.compactMapKeys(DateFormatter.dateDashed.date(from:))
        }
    }

    /// Query HealthKit for steps that occured during a workout. Steps aren't recorded within workouts, so a separate query must be used.
    /// - Parameter workout: The workout to fetch the steps for
    /// - Returns: Steps by date
    private func steps(for workout: HKWorkout) async throws -> [Date: Double] {
        let dateInterval = DateInterval(start: workout.startDate, end: workout.endDate)

        let predicate = HKQuery.predicateForSamples(
            withStart: dateInterval.start,
            end: dateInterval.end
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = StepsQuery(predicate: predicate) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let steps):
                    continuation.resume(returning: [workout.startDate: steps])
                }
            }
            healthKitManager.execute(query)
        }
    }

    /// Get the total points by date for a given workout and sample type
    /// - Parameters:
    ///   - sampleType: The sample type to fetch the points for
    ///   - workout: The workout to fetch the points for
    ///   - unit: The unit
    /// - Throws: Any errors from HealthKit
    /// - Returns: Points by date
    private func pointsByDate(sampleType: HKQuantityType, workout: HKWorkout, unit: HKUnit) async throws -> [Date: Double] {
        // https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/adding_samples_to_a_workout
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Date: Double], Error>)  in
            let query = SampleQuery(sampleType: sampleType, unit: unit, predicate: predicate) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let results):
                    continuation.resume(returning: results)
                }
            }
            healthKitManager.execute(query)
        }
    }
}

extension Dictionary where Key == WorkoutType, Value == [WorkoutMetric] {
    static var all: Self {
        let pairs = WorkoutType.allCases.map { ($0, $0.metrics) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
