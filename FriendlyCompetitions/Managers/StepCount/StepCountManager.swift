import Combine
import ECKit
import Factory
import FCKit
import Foundation
import HealthKit

// sourcery: AutoMockable
protocol StepCountManaging: AnyObject {
    func stepCounts(in dateInterval: DateInterval) -> AnyPublisher<[StepCount], Error>
}

final class StepCountManager: StepCountManaging {

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.database) private var database: Database
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.healthKitManager) private var healthKitManager: HealthKitManaging
    @Injected(\.userManager) private var userManager: UserManaging

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        healthKitManager.registerBackgroundDeliveryTask(for: .stepCount, task: fetchAndUpload)

        fetchAndUpload()
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func stepCounts(in dateInterval: DateInterval) -> AnyPublisher<[StepCount], Error> {
        guard let days = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day else { return .just([]) }
        return (0 ... days).compactMap { offset -> AnyPublisher<StepCount?, Never>? in
            let start = Calendar.current
                .startOfDay(for: dateInterval.start)
                .addingTimeInterval(TimeInterval(offset).days)

            guard start <= .now else { return nil }
            let endOfStart = Calendar.current.startOfDay(for: start).addingTimeInterval(24.hours - 1.seconds)
            let end = min(endOfStart, .now)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            return Future<StepCount?, Error> { [weak self] promise in
                let query = StepsQuery(predicate: predicate) { result in
                    switch result {
                    case .failure(let error):
                        promise(Result<StepCount?, Error>.failure(error))
                    case .success(let steps):
                        let count = StepCount(count: Int(steps), date: start)
                        promise(.success(count))
                    }
                }
                self?.healthKitManager.execute(query)
            }
            .catchErrorJustReturn(nil)
            .eraseToAnyPublisher()
        }
        .combineLatest()
        .compactMapMany { $0 }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func fetchAndUpload() -> AnyPublisher<Void, Never> {
        competitionsManager.competitions
            .filterMany { [weak self] competition in
                guard let self else { return false }
                let gracePeriod = self.featureFlagManager.value(forDouble: .dataUploadGracePeriodHours).hours
                guard competition.canUploadData(gracePeriod: gracePeriod) else { return false }
                switch competition.scoringModel {
                case .stepCount:
                    return true
                case .activityRingCloseCount, .percentOfGoals, .rawNumbers, .workout:
                    return false
                }
            }
            .map { competitions in
                if let dateInterval = competitions.dateInterval {
                    return dateInterval.combined(with: .dataFetchDefault)
                } else {
                    return .dataFetchDefault
                }
            }
            .removeDuplicates()
            .flatMapLatest(withUnretained: self) { strongSelf, dateInterval in
                strongSelf.healthKitManager.shouldRequest([.stepCount])
                    .flatMapLatest { shouldRequest -> AnyPublisher<[StepCount], Error> in
                        guard !shouldRequest else { return .just([]) }
                        return strongSelf.stepCounts(in: dateInterval)
                    }
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }
            .flatMapLatest(withUnretained: self) { strongSelf, stepCounts in
                strongSelf.upload(stepCounts: stepCounts)
                    .catchErrorJustReturn(())
            }
            .eraseToAnyPublisher()
    }

    private func upload(stepCounts: [StepCount]) -> AnyPublisher<Void, Error> {

        let changedStepCounts = database
            .collection("users/\(userManager.user.id)/steps")
            .getDocuments(ofType: StepCount.self, source: .cache)
            .map { cached in
                stepCounts
                    .subtracting(cached)
                    .sorted(by: \.date)
            }

        return changedStepCounts
            .flatMapLatest(withUnretained: self) { strongSelf, stepCounts in
                let userID = strongSelf.userManager.user.id
                let batch = strongSelf.database.batch()
                stepCounts.forEach { stepCount in
                    let document = strongSelf.database.document("users/\(userID)/steps/\(stepCount.id)")
                    batch.set(value: stepCount, forDocument: document)
                }
                return batch.commit()
            }
            .eraseToAnyPublisher()
    }
}
