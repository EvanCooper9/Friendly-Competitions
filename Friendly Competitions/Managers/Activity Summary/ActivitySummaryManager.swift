import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Firebase
import FirebaseFirestore
import Foundation
import HealthKit

// sourcery: AutoMockable
protocol ActivitySummaryManaging {
    var activitySummary: AnyPublisher<ActivitySummary?, Never> { get }
    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error>
}

final class ActivitySummaryManager: ActivitySummaryManaging {

    // MARK: - Public Properties

    var activitySummary: AnyPublisher<ActivitySummary?, Never> {
        activitySummarySubject
            .removeDuplicates()
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    @Injected(\.activitySummaryCache) private var cache
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.database) private var database
    @Injected(\.scheduler) private var scheduler
    @Injected(\.userManager) private var userManager
    @Injected(\.workoutManager) private var workoutManager

    private var helper: HealthKitDataHelper<[ActivitySummary]>!

    private var activitySummarySubject = ReplaySubject<ActivitySummary?, Never>(bufferSize: 1)
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        helper = HealthKitDataHelper { [weak self] dateInterval in
            self?.activitySummaries(in: dateInterval) ?? .just([])
        } upload: { [weak self] in
            self?.upload(activitySummaries: $0) ?? .just(())
        }

        let storedActivitySummary = cache.activitySummary
        activitySummarySubject.send(storedActivitySummary?.date.isToday == true ? storedActivitySummary : nil)
        activitySummary
            .sink(withUnretained: self) { $0.cache.activitySummary = $1 }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error> {
        Future { [weak self] promise in
            let query = ActivitySummaryQuery(predicate: dateInterval.activitySummaryPredicate) { [weak self] result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let activitySummaries):
                    if let activitySummary = activitySummaries.last, activitySummary.date.isToday {
                        self?.activitySummarySubject.send(activitySummary)
                    } else {
                        self?.activitySummarySubject.send(nil)
                    }
                    promise(.success(activitySummaries))
                }
            }
            self?.healthKitManager.execute(query)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func upload(activitySummaries: [ActivitySummary]) -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            guard let strongSelf = self else { return }
            let userID = strongSelf.userManager.user.id
            let batch = strongSelf.database.batch()
            try activitySummaries.forEach { activitySummary in
                var activitySummary = activitySummary
                activitySummary.userID = userID
                let document = strongSelf.database.document("users/\(userID)/activitySummaries/\(activitySummary.id)")
                try batch.set(value: activitySummary, forDocument: document)
            }
            try await batch.commit()
        }
    }
}

private extension DateInterval {
    var activitySummaryPredicate: NSPredicate {
        let calendar = Calendar.current
        let units: Set<Calendar.Component> = [.day, .month, .year, .era]
        var startDateComponents = calendar.dateComponents(units, from: start)
        startDateComponents.calendar = calendar
        var endDateComponents = calendar.dateComponents(units, from: end)
        endDateComponents.calendar = calendar
        return HKQuery.predicate(forActivitySummariesBetweenStart: startDateComponents, end: endDateComponents)
    }
}
