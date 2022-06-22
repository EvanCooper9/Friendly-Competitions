import Combine
import CombineExt
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import Foundation
import HealthKit
import Resolver

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
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var healthKitManager: HealthKitManaging
    @Injected private var database: Firestore
    @Injected private var userManager: UserManaging

    private var _activitySummary = PassthroughSubject<ActivitySummary?, Never>()

    private let upload = PassthroughSubject<[ActivitySummary], Never>()
    private let uploadFinished = PassthroughSubject<Void, Error>()
    private let query = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init() {
        Publishers
            .Merge(healthKitManager.backgroundDeliveryReceived, query)
            .prepend(())
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .flatMapLatest(requestActivitySummaries)
            .removeDuplicates()
            .filter(\.isNotEmpty)
            .combineLatest(userManager.user)
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
            .map { competitions -> DateInterval in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                let now = Calendar.current.date(from: components) ?? .now
                let yesterday = now.addingTimeInterval(-1.days)
                let tomorrow = now.addingTimeInterval(1.days)
                return competitions
                    .filter(\.isActive)
                    .reduce(DateInterval(start: yesterday, end: tomorrow)) { dateInterval, competition in
                        .init(
                            start: [dateInterval.start, competition.start, yesterday].min() ?? yesterday,
                            end: [dateInterval.end, competition.end, tomorrow].max() ?? tomorrow
                        )
                    }
            }
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
