import FCKit
import HealthKit

protocol HealthKitQuery {
    associatedtype Data
    var resultsHandler: (Result<Data, Error>) -> Void { get }
    var underlyingQuery: HKQuery { get }
}

/// Required typealias so that sourcery can generate mocks for type `any HealthKitQuery`
typealias AnyHealthKitQuery = any HealthKitQuery

// MARK: - HealthKit Implementations

final class ActivitySummaryQuery: HealthKitQuery {

    typealias Data = [ActivitySummary]

    let resultsHandler: (Result<Data, Error>) -> Void
    let underlyingQuery: HKQuery

    init(predicate: NSPredicate, resultsHandler: @escaping (Result<Data, Error>) -> Void) {
        self.resultsHandler = resultsHandler

        underlyingQuery = HKActivitySummaryQuery(predicate: predicate, resultsHandler: { _, results, error in
            if let error {
                error.reportToCrashlytics(userInfo: [
                    "queryType": String(describing: Self.self),
                    "predicateFormat": predicate.predicateFormat
                ])
                resultsHandler(.failure(error))
            } else {
                let activitySummaries = results?.map(\.activitySummary) ?? []
                resultsHandler(.success(activitySummaries))
            }
        })
    }
}

final class WorkoutQuery: HealthKitQuery {

    typealias Data = [HKWorkout]

    let resultsHandler: (Result<Data, Error>) -> Void
    let underlyingQuery: HKQuery

    init(predicate: NSPredicate, dateInterval: DateInterval, resultsHandler: @escaping (Result<Data, Error>) -> Void) {
        self.resultsHandler = resultsHandler

        let sampleType = HKSampleType.workoutType()
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        underlyingQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) { _, workouts, error in
            if let error {
                error.reportToCrashlytics(userInfo: [
                    "queryType": String(describing: Self.self),
                    "predicateFormat": predicate.predicateFormat
                ])
                resultsHandler(.failure(error))
            } else {
                let workouts = workouts?
                    .compactMap { $0 as? HKWorkout }
                    .filter { dateInterval.contains($0.startDate) && dateInterval.contains($0.endDate) }
                resultsHandler(.success(workouts ?? []))
            }
        }
    }
}

final class StepsQuery: HealthKitQuery {

    typealias Data = Double

    let resultsHandler: (Result<Data, Error>) -> Void
    let underlyingQuery: HKQuery

    init(predicate: NSPredicate, resultsHandler: @escaping (Result<Data, Error>) -> Void) {
        self.resultsHandler = resultsHandler

        underlyingQuery = HKStatisticsQuery(
            quantityType: HKQuantityType(.stepCount),
            quantitySamplePredicate: predicate) { _, stats, error in
                if let error {
                    error.reportToCrashlytics(userInfo: [
                        "queryType": String(describing: Self.self),
                        "predicateFormat": predicate.predicateFormat
                    ])
                    resultsHandler(.failure(error))
                } else {
                    let steps = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    resultsHandler(.success(steps))
                }
            }
    }
}

final class SampleQuery: HealthKitQuery {

    typealias Data = [Date: Double]

    let resultsHandler: (Result<Data, Error>) -> Void
    let underlyingQuery: HKQuery

    init(sampleType: HKSampleType, unit: HKUnit, predicate: NSPredicate, resultsHandler: @escaping (Result<Data, Error>) -> Void) {
        self.resultsHandler = resultsHandler

        underlyingQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 0, sortDescriptors: nil) { _, samples, error in
            if let error {
                error.reportToCrashlytics(userInfo: [
                    "queryType": String(describing: Self.self),
                    "predicateFormat": predicate.predicateFormat
                ])
                resultsHandler(.failure(error))
            } else if let samples {
                let total = samples
                    .compactMap { $0 as? HKQuantitySample }
                    .enumerated()
                    .reduce(into: [Date: Double]()) { partialResult, next in
                        let (offset, sample) = next
                        let dateNoTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: sample.endDate)!
                        let metric = WorkoutMetric(from: sampleType.identifier)
                        switch metric {
                        case .heartRate:
                            let points = sample.quantity.doubleValue(for: unit)
                            let oldAverage = partialResult[dateNoTime] ?? 0
                            let oldTotal = oldAverage * Double(offset)
                            let newTotal = oldTotal + points
                            let newAverage = newTotal / Double(offset + 1)
                            partialResult[dateNoTime] = newAverage
                        case .distance, .steps, .none:
                            partialResult[dateNoTime] = (partialResult[dateNoTime] ?? 0) + sample.quantity.doubleValue(for: unit)
                        }
                    }
                resultsHandler(.success(total))
            } else {
                resultsHandler(.success([:]))
            }
        }
    }
}

final class ObserverQuery: HealthKitQuery {

    typealias Data = () -> Void

    let resultsHandler: (Result<Data, Error>) -> Void
    let underlyingQuery: HKQuery

    init(sampleType: HKSampleType, resultsHandler: @escaping (Result<Data, Error>) -> Void) {
        self.resultsHandler = resultsHandler

        underlyingQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completion, error in
            if let error {
                resultsHandler(.failure(error))
                completion()
            } else {
                resultsHandler(.success(completion))
            }
        }
    }
}
