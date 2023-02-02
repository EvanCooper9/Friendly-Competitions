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
    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error>
}

final class ActivitySummaryManager: ActivitySummaryManaging {
    
    private enum Constants {
        static var activitySummaryKey: String { #function }
    }

    // MARK: - Public Properties

    let activitySummary: AnyPublisher<ActivitySummary?, Never>

    // MARK: - Private Properties

    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.healthKitManager) private var healthKitManager
    @Injected(Container.database) private var database
    @Injected(Container.userManager) private var userManager
    @Injected(Container.workoutManager) private var workoutManager

    private var activitySummarySubject: CurrentValueSubject<ActivitySummary?, Never>
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let storedActivitySummary = UserDefaults.standard.decode(ActivitySummary.self, forKey: Constants.activitySummaryKey)
        activitySummarySubject = .init(storedActivitySummary?.date.isToday == true ? storedActivitySummary : nil)
        activitySummarySubject
            .dropFirst()
            .sink { UserDefaults.standard.encode($0, forKey: Constants.activitySummaryKey) }
            .store(in: &cancellables)

        activitySummary = activitySummarySubject
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .share(replay: 1)
            .eraseToAnyPublisher()
        
        let fetchAndUpload = PassthroughSubject<DateInterval, Error>()
        let fetchAndUploadFinished = PassthroughSubject<Void, Never>()
        
        fetchAndUpload
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .flatMapLatest(withUnretained: self) { $0.activitySummaries(in: $1) }
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, activitySummaries in
                if let activitySummary = activitySummaries.last, activitySummary.date.isToday {
                    strongSelf.activitySummarySubject.send(activitySummary)
                } else {
                    strongSelf.activitySummarySubject.send(nil)
                }
            })
            .flatMapLatest(withUnretained: self) { $0.upload(activitySummaries: $1) }
            .sink(receiveCompletion: { _ in }, receiveValue: { fetchAndUploadFinished.send() })
            .store(in: &cancellables)
        
        let backgroundDeliveryTrigger = Just(())
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                fetchAndUpload.send(strongSelf.competitionsManager.competitionsDateInterval)
            })
            .flatMapLatest { fetchAndUploadFinished }
            .eraseToAnyPublisher()
        
        healthKitManager.registerBackgroundDeliveryTask(backgroundDeliveryTrigger)
        
        Publishers
            .Merge(
                UIApplication.willEnterForegroundNotification.publisher
                    .map { [weak self] _ in self?.competitionsManager.competitionsDateInterval }
                    .unwrap(),
                competitionsManager.competitions
                    .filterMany(\.isActive)
                    .map(\.dateInterval)
            )
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink(receiveValue: { fetchAndUpload.send($0) })
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    
    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error> {
        print("fetching ACs in interval \(dateInterval)")
        let subject = PassthroughSubject<[ActivitySummary], Error>()
        let query = HKActivitySummaryQuery(predicate: dateInterval.activitySummaryPredicate) { query, hkActivitySummaries, error in
            if let error {
                subject.send(completion: .failure(error))
                return
            }
            subject.send(hkActivitySummaries?.map(\.activitySummary) ?? [])
            subject.send(completion: .finished)
        }
        return subject
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                strongSelf.healthKitManager.execute(query)
            })
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
                let _ = try batch.setDataEncodable(activitySummary, forDocument: document)
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
