import Combine
import ECKit
import Factory
import Firebase
import FirebaseFirestore
import HealthKit
import UIKit

// sourcery: AutoMockable
protocol WorkoutManaging: AnyObject {
    func workouts(of type: WorkoutType, with metrics: [WorkoutMetric], in dateInterval: DateInterval) -> AnyPublisher<[Workout], Error>
}

final class WorkoutManager: WorkoutManaging {

    private enum Constants {
        static var cachedWorkoutMetricsKey: String { #function }
    }

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.database) private var database
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.stepCountManager) private var stepCountManager
    @Injected(\.userManager) private var userManager

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        healthKitManager.registerBackgroundDeliveryTask(fetchAndUpload())
        fetchAndUpload()
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func workouts(of type: WorkoutType, with metrics: [WorkoutMetric], in dateInterval: DateInterval) -> AnyPublisher<[Workout], Error> {
        workoutMetricDataByDate(ofType: type, metrics: metrics, during: dateInterval)
            .mapMany { date, workoutMetricData in
                let points = workoutMetricData.compactMap { sampleType, points -> (WorkoutMetric, Int)? in
                    guard let metric = WorkoutMetric(from: sampleType.identifier) else { return nil }
                    return (metric, Int(points))
                }

                return Workout(
                    type: type,
                    date: date,
                    points: Dictionary(uniqueKeysWithValues: points)
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func fetchAndUpload() -> AnyPublisher<Void, Never> {

        struct CompetitionFetchData: Equatable {
            let dateInterval: DateInterval
            let workoutType: WorkoutType
            let workoutMetrics: [WorkoutMetric]
        }

        return competitionsManager.competitions
            .filterMany(\.isActive)
            .compactMapMany { competition in
                let dateInterval = DateInterval(start: competition.start, end: competition.end)
                switch competition.scoringModel {
                case let .workout(workoutType, workoutMetrics):
                    return CompetitionFetchData(dateInterval: dateInterval,
                                                workoutType: workoutType,
                                                workoutMetrics: workoutMetrics)
                default:
                    return nil
                }
            }
            .flatMapLatest(withUnretained: self) { strongSelf, results -> AnyPublisher<[Workout], Never> in
                results.map { (fetchData: CompetitionFetchData) in
                    let permissions = fetchData.workoutMetrics.compactMap { $0.permission(for: fetchData.workoutType) }
                    return strongSelf.healthKitManager.shouldRequest(permissions)
                        .flatMapLatest { shouldRequest -> AnyPublisher<[Workout], Error> in
                            guard !shouldRequest else { return .just([]) }
                            return strongSelf.workouts(of: fetchData.workoutType, with: fetchData.workoutMetrics, in: fetchData.dateInterval)
                        }
                        .catchErrorJustReturn([])
                        .eraseToAnyPublisher()
                }
                .combineLatest()
                .map { $0.reduce([Workout](), +) }
                .eraseToAnyPublisher()
            }
            .flatMapLatest(withUnretained: self) { strongSelf, workouts in
                strongSelf.upload(workouts: workouts)
                    .catchErrorJustReturn(())
            }
            .eraseToAnyPublisher()
    }

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
            .flatMapLatest(withUnretained: self) { strongSelf, workouts in
                let userID = strongSelf.userManager.user.id
                let batch = strongSelf.database.batch()
                workouts.forEach { workout in
                    let document = strongSelf.database.document("users/\(userID)/workouts/\(workout.id)")
                    batch.set(value: workout, forDocument: document)
                }
                return batch.commit()
            }
            .eraseToAnyPublisher()
    }

    private func workoutMetricDataByDate(ofType workoutType: WorkoutType, metrics: [WorkoutMetric], during dateInterval: DateInterval) -> AnyPublisher<[Date: [HKQuantityType: Double]], Error> {
        workouts(for: workoutType.hkWorkoutActivityType, in: dateInterval)
            .flatMap(withUnretained: self) { strongSelf, workouts in
                workouts
                    .map { strongSelf.pointsByDateByMetric(for: $0, metrics: metrics) }
                    .combineLatest()
            }
            .map { results in
                var toReturn = [Date: [HKQuantityType: Double]]()
                for pointsByDateBySample in results {
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
            .eraseToAnyPublisher()
    }

    private func workouts(for workoutType: HKWorkoutActivityType, in dateInterval: DateInterval) -> AnyPublisher<[HKWorkout], Error> {
        Future { [weak self] promise in
            guard let self else { return }
            let predicate = HKQuery.predicateForWorkouts(with: workoutType)
            let query = WorkoutQuery(predicate: predicate, dateInterval: dateInterval) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let workouts):
                    promise(.success(workouts))
                }
            }
            self.healthKitManager.execute(query)
        }
        .eraseToAnyPublisher()
    }

    /// Get the total points by date for all sample types of a given workout
    /// - Parameter workout: The workout to fetch the points for
    /// - Parameter metrics: The metrics to fetch points for
    /// - Throws: Any errors from  HealthKit
    /// - Returns: Points by date by sample type
    private func pointsByDateByMetric(for workout: HKWorkout, metrics: [WorkoutMetric]) -> AnyPublisher<[Date: [HKQuantityType: Double]], Error> {
        guard let workoutType = WorkoutType(hkWorkoutActivityType: workout.workoutActivityType) else { return .just([:]) }
        return metrics
            .compactMap { metric -> (HKQuantityType, WorkoutMetric)? in
                guard let sample = metric.sample(for: workoutType) else { return nil }
                return (sample, metric)
            }
            .map { sample, metric -> AnyPublisher<(HKQuantityType, [Date: Double]), Error> in
                switch metric {
                case .steps:
                    // Steps are not actually recorded in workouts. A separate type of query is required
                    let dateInterval = DateInterval(start: workout.startDate, end: workout.endDate)
                    return stepCountManager.stepCounts(in: dateInterval)
                        .map { stepCounts in
                            let pairs = stepCounts.map { ($0.date, Double($0.count)) }
                            return Dictionary(uniqueKeysWithValues: pairs)
                        }
                        .map { (sample, $0) }
                        .eraseToAnyPublisher()
                default:
                    return pointsByDate(sampleType: sample, workout: workout, unit: metric.unit)
                        .map { (sample, $0) }
                        .eraseToAnyPublisher()
                }
            }
            .combineLatest()
            .map { results in
                var toReturn = [String: [HKQuantityType: Double]]()
                for (sampleType, pointsByDate) in results {
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
            .eraseToAnyPublisher()
    }

    /// Get the total points by date for a given workout and sample type
    /// - Parameters:
    ///   - sampleType: The sample type to fetch the points for
    ///   - workout: The workout to fetch the points for
    ///   - unit: The unit
    /// - Throws: Any errors from HealthKit
    /// - Returns: Points by date
    private func pointsByDate(sampleType: HKQuantityType, workout: HKWorkout, unit: HKUnit) -> AnyPublisher<[Date: Double], Error> {
        // https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/adding_samples_to_a_workout
        let predicate = HKQuery.predicateForObjects(from: workout)

        return Future { [weak self] promise in
            guard let self else { return }
            let query = SampleQuery(sampleType: sampleType, unit: unit, predicate: predicate) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let results):
                    promise(.success(results))
                }
            }
            self.healthKitManager.execute(query)
        }
        .eraseToAnyPublisher()
    }
}

extension Dictionary where Key == WorkoutType, Value == [WorkoutMetric] {
    static var all: Self {
        let pairs = WorkoutType.allCases.map { ($0, $0.metrics) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
