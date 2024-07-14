import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import FCKit
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

    @Injected(\.activitySummaryCache) private var cache: ActivitySummaryCache
    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.database) private var database: Database
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.healthKitManager) private var healthKitManager: HealthKitManaging
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.userManager) private var userManager: UserManaging

    private var activitySummarySubject = ReplaySubject<ActivitySummary?, Never>(bufferSize: 1)
    private var fetchAndUploadPublisher: AnyPublisher<Void, Never>?
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let storedActivitySummary = cache.activitySummary
        activitySummarySubject.send(storedActivitySummary?.date.isToday == true ? storedActivitySummary : nil)
        activitySummary
            .sink(withUnretained: self) { $0.cache.activitySummary = $1 }
            .store(in: &cancellables)

        fetchAndUpload()
            .sink()
            .store(in: &cancellables)

        registerForBackgroundDelivery()
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

    private func registerForBackgroundDelivery() {
        let permissionTypes: [HealthKitPermissionType] = [
            .activeEnergy,
            .appleExerciseTime,
            .appleMoveTime,
            .appleStandTime,
            .appleStandHour,
            .activitySummaryType
        ]

        permissionTypes.forEach { permission in
            healthKitManager.registerBackgroundDeliveryTask(for: permission) { [weak self] in
                guard let self else { return .just(()) }
                if let fetchAndUploadPublisher = self.fetchAndUploadPublisher {
                    return fetchAndUploadPublisher
                } else {
                    let publisher = fetchAndUpload()
                        .first()
                        .handleEvents(receiveCompletion: { _ in
                            self.fetchAndUploadPublisher = nil
                        }, receiveCancel: {
                            self.fetchAndUploadPublisher = nil
                        })
                        .share()
                        .eraseToAnyPublisher()
                    self.fetchAndUploadPublisher = publisher
                    return publisher
                }
            }
        }
    }

    private func fetchAndUpload() -> AnyPublisher<Void, Never> {
        competitionsManager.competitions
            .filterMany { [weak self] competition in
                guard let self else { return false }
                let gracePeriod = self.featureFlagManager.value(forDouble: .dataUploadGracePeriodHours).hours
                guard competition.canUploadData(gracePeriod: gracePeriod) else { return false }
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
