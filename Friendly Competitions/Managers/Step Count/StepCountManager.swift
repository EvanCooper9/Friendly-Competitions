import Combine
import ECKit
import Factory
import Foundation
import HealthKit

// sourcery: Mockable
protocol StepCountManaging {
    func stepCounts(in dateInterval: DateInterval) -> AnyPublisher<[StepCount], Error>
}

final class StepCountManager: StepCountManaging {

    // MARK: - Private Properties

    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.healthKitDataHelperBuilder) private var healthKitDataHelperBuilder
    @Injected(\.database) private var database
    @Injected(\.userManager) private var userManager

    private var helper: (any HealthKitDataHelping<[StepCount]>)!

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        helper = healthKitDataHelperBuilder.bulid { [weak self] dateInterval in
            guard let strongSelf = self else { return .just([]) }
            return strongSelf.stepCounts(in: dateInterval)
        } upload: { [weak self] stepCounts in
            self?.upload(stepCounts: stepCounts) ?? .just(())
        }
    }

    // MARK: - Public Methods

    func stepCounts(in dateInterval: DateInterval) -> AnyPublisher<[StepCount], Error> {
        (0 ..< Int(dateInterval.duration / 24.hours))
            .compactMap { offset -> AnyPublisher<StepCount, Error>? in
                let start = dateInterval.start.addingTimeInterval(24.hours * TimeInterval(offset))
                let end = start.addingTimeInterval(24.hours - 1.seconds)
                guard start < .now else { return nil }

                let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
                return Future { [weak self] promise in
                    let query = StepsQuery(predicate: predicate) { result in
                        switch result {
                        case .failure(let error):
                            promise(.failure(error))
                        case .success(let steps):
                            promise(.success(.init(count: Int(steps), date: start)))
                        }
                    }
                    self?.healthKitManager.execute(query)
                }
                .eraseToAnyPublisher()
            }
            .combineLatest()
    }

    // MARK: - Private Methods

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
