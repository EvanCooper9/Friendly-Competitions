import Combine
import CombineExt
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import Foundation
import HealthKit
import Resolver
import UIKit

// sourcery: AutoMockable
protocol ActivitySummaryManaging {
    var activitySummary: AnyPublisher<ActivitySummary?, Never> { get }
    func update() -> AnyPublisher<Void, Error>
}

final class ActivitySummaryManager: ActivitySummaryManaging {

    // MARK: - Public Properties

    var activitySummary: AnyPublisher<ActivitySummary?, Never> {
        _activitySummary
            .receive(on: RunLoop.main)
            .share(replay: 1)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var healthKitManager: HealthKitManaging
    @Injected private var database: Firestore
    @Injected private var userManager: UserManaging
    @Injected private var workoutManager: WorkoutManaging

    private var _activitySummary = PassthroughSubject<ActivitySummary?, Never>()

    private let upload = PassthroughSubject<[ActivitySummary], Never>()
    private let uploadFinished = PassthroughSubject<Void, Error>()
    private let query = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        Publishers
            .Merge3(
                healthKitManager.backgroundDeliveryReceived,
                query,
                NotificationCenter.default
                    .publisher(for: UIApplication.willEnterForegroundNotification)
                    .mapToValue(())
            )
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .flatMapLatest(withUnretained: self) {
                $0.healthKitManager.permissionStatus
                    .filter { $0 == .authorized }
                    .mapToValue(())
                    .eraseToAnyPublisher()
            }
            .flatMapLatest(requestActivitySummaries)
            .removeDuplicates()
            .filter(\.isNotEmpty)
            .combineLatest(userManager.user)
//            .dropFirst(999)
            .sinkAsync { [weak self] activitySummaries, user in
                guard let self = self else { return }
                let batch = self.database.batch()
                try activitySummaries.forEach { activitySummary in
                    let documentId = DateFormatter.dateDashed.string(from: activitySummary.date)
                    let document = self.database.document("users/\(user.id)/activitySummaries/\(documentId)")
                    let _ = try batch.setDataEncodable(activitySummary, forDocument: document)
                }
                try await batch.commit()
                self.uploadFinished.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func update() -> AnyPublisher<Void, Error> {
        uploadFinished
            .handleEvents(receiveSubscription: { [weak self] _ in self?.query.send() })
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Don't call this directly, call `query` instead
    private func requestActivitySummaries() -> AnyPublisher<[ActivitySummary], Never> {
        competitionsManager.competitions
            .map { $0.filter(\.isActive).dateInterval }
            .flatMap { [weak self] dateInterval -> AnyPublisher<[ActivitySummary], Error> in
                guard let self = self else { return .never() }
                let subject = PassthroughSubject<[ActivitySummary], Error>()
                let query = HKActivitySummaryQuery(predicate: dateInterval.activitySummaryPredicate) { query, hkActivitySummaries, error in
                    if let error = error {
                        subject.send(completion: .failure(error))
                        return
                    }

                    let activitySummaries = hkActivitySummaries?.map(\.activitySummary) ?? []

                    if let activitySummary = activitySummaries.last, activitySummary.date.isToday {
                        self._activitySummary.send(activitySummary)
                    }

                    subject.send(activitySummaries)
                }
                self.healthKitManager.execute(query)
                return subject.eraseToAnyPublisher()
            }
            .ignoreFailure()
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
