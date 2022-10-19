import Combine
import CombineExt
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseFirestore
import Foundation
import HealthKit

// sourcery: AutoMockable
protocol ActivitySummaryManaging {
    var activitySummary: AnyPublisher<ActivitySummary?, Never> { get }
    func update() -> AnyPublisher<Void, Error>
}

final class ActivitySummaryManager: ActivitySummaryManaging {

    // MARK: - Public Properties

    let activitySummary: AnyPublisher<ActivitySummary?, Never>

    // MARK: - Private Properties

    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.healthKitManager) private var healthKitManager
    @Injected(Container.database) private var database
    @Injected(Container.userManager) private var userManager
    @Injected(Container.workoutManager) private var workoutManager

    private var _activitySummary: CurrentValueSubject<ActivitySummary?, Never>

    private let upload = PassthroughSubject<[ActivitySummary], Never>()
    private let uploadFinished = PassthroughSubject<Void, Error>()
    private let query = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let storedActivitySummary = UserDefaults.standard.decode(ActivitySummary.self, forKey: "activity_summary")
        _activitySummary = .init(storedActivitySummary)

        activitySummary = _activitySummary
            .removeDuplicates()
            .handleEvents(receiveOutput: { UserDefaults.standard.encode($0, forKey: "activity_summary") })
            .receive(on: RunLoop.main)
            .share(replay: 1)
            .eraseToAnyPublisher()

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
            .sinkAsync { [weak self] activitySummaries, user in
                guard let strongSelf = self else { return }
            
                if let activitySummary = activitySummaries.last, activitySummary.date.isToday {
                    strongSelf._activitySummary.send(activitySummary)
                }

                let batch = strongSelf.database.batch()
                try activitySummaries.forEach { activitySummary in
                    var activitySummary = activitySummary
                    activitySummary.userID = user.id
                    let documentId = DateFormatter.dateDashed.string(from: activitySummary.date)
                    let document = strongSelf.database.document("users/\(user.id)/activitySummaries/\(documentId)")
                    let _ = try batch.setDataEncodable(activitySummary, forDocument: document)
                }
                try await batch.commit()
                strongSelf.uploadFinished.send()
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
            .filterMany(\.isActive)
            .map(\.dateInterval)
            .flatMap { [weak self] dateInterval -> AnyPublisher<[ActivitySummary], Error> in
                guard let self = self else { return .never() }
                let subject = PassthroughSubject<[ActivitySummary], Error>()
                let query = HKActivitySummaryQuery(predicate: dateInterval.activitySummaryPredicate) { query, hkActivitySummaries, error in
                    if let error {
                        subject.send(completion: .failure(error))
                        return
                    }
                    subject.send(hkActivitySummaries?.map(\.activitySummary) ?? [])
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
