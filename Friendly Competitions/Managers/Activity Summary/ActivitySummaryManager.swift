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
protocol ActivitySummaryManaging: AnyObject {
    var activitySummary: AnyPublisher<ActivitySummary?, Never> { get }
    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error>
}

final class ActivitySummaryManager: ActivitySummaryManaging {

    // MARK: - Public Properties

    private(set) lazy var activitySummary: AnyPublisher<ActivitySummary?, Never> = {
        activitySummarySubject
            .removeDuplicates()
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }()

    // MARK: - Private Properties

    @Injected(\.activitySummaryCache) private var cache
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.database) private var database
    @Injected(\.scheduler) private var scheduler
    @Injected(\.userManager) private var userManager

    private var activitySummarySubject = ReplaySubject<ActivitySummary?, Never>(bufferSize: 1)
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let storedActivitySummary = cache.activitySummary
        activitySummarySubject.send(storedActivitySummary?.date.isToday == true ? storedActivitySummary : nil)
        activitySummary
            .sink(withUnretained: self) { $0.cache.activitySummary = $1 }
            .store(in: &cancellables)

        let permissionTypes: [HealthKitPermissionType] = [
            .activeEnergy,
            .appleExerciseTime,
            .appleMoveTime,
            .appleStandTime,
            .appleStandHour,
            .activitySummaryType
        ]
        permissionTypes.forEach { permission in
            healthKitManager.registerBackgroundDeliveryTask(fetchAndUpload(), for: permission)
        }

        fetchAndUpload()
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error> {
        Future { [weak self] promise in
            let query = ActivitySummaryQuery(predicate: dateInterval.activitySummaryPredicate) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let activitySummaries):
                    promise(.success(activitySummaries))
                }
            }
            self?.healthKitManager.execute(query)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func fetchAndUpload() -> AnyPublisher<Void, Never> {
        competitionsManager.competitions
            .filterMany { competition in
                guard competition.isActive else { return false }
                switch competition.scoringModel {
                case .activityRingCloseCount, .percentOfGoals, .rawNumbers:
                    return true
                case .stepCount, .workout:
                    return false
                }
            }
            .map { $0.dateInterval?.combined(with: .dataFetchDefault) ?? .dataFetchDefault }
            .removeDuplicates()
            .flatMapLatest(withUnretained: self) { strongSelf, dateInterval in
                strongSelf.healthKitManager
                    .shouldRequest([.activitySummaryType])
                    .flatMapLatest { shouldRequest -> AnyPublisher<[ActivitySummary], Error> in
                        guard !shouldRequest else { return .just([]) }
                        return strongSelf.activitySummaries(in: dateInterval)
                    }
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, activitySummaries in
                if let activitySummary = activitySummaries.last, activitySummary.date.isToday {
                    strongSelf.activitySummarySubject.send(activitySummary)
                } else {
                    strongSelf.activitySummarySubject.send(nil)
                }
            })
            .flatMapLatest(withUnretained: self) { strongSelf, activitySummaries in
                strongSelf.upload(activitySummaries: activitySummaries)
                    .catchErrorJustReturn(())
            }
            .eraseToAnyPublisher()
    }

    private func upload(activitySummaries: [ActivitySummary]) -> AnyPublisher<Void, Error> {
        let activitySummaries = activitySummaries.map { $0.with(userID: userManager.user.id) }

        let changedActivitySummaries = database
            .collection("users/\(userManager.user.id)/activitySummaries")
            .getDocuments(ofType: ActivitySummary.self, source: .cache)
            .map { cached in
                activitySummaries
                    .subtracting(cached)
                    .sorted(by: \.date)
            }

        return changedActivitySummaries
            .flatMapLatest(withUnretained: self) { strongSelf, activitySummaries in
                let batch = strongSelf.database.batch()
                activitySummaries.forEach { activitySummary in
                    let document = strongSelf.database.document(activitySummary.databasePath)
                    batch.set(value: activitySummary, forDocument: document)
                }
                return batch.commit()
            }
            .eraseToAnyPublisher()
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

extension Array where Element: Hashable {
    func subtracting(_ other: Self) -> Self {
        Array(Set(self).subtracting(Set(other)))
    }
}
