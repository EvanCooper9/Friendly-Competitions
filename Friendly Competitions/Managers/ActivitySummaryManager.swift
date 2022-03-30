import Combine
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import Foundation
import HealthKit
import Resolver

class AnyActivitySummaryManager: ObservableObject {
    @Published(storedWithKey: "activitySummary") var activitySummary: ActivitySummary? = nil
    func update() async throws {}
}

final class ActivitySummaryManager: AnyActivitySummaryManager {

    // MARK: - Private Properties

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var healthKitManager: AnyHealthKitManager
    @Injected private var database: Firestore
    @Injected private var userManager: AnyUserManager

    private var user: User { userManager.user }

    private var cancellables = Set<AnyCancellable>()
    private let upload = PassthroughSubject<[ActivitySummary], Never>()
    private let query = PassthroughSubject<Void, Never>()

    // MARK: - Lifecycle

    override init() {
        super.init()

        if activitySummary?.date.isToday == false {
            activitySummary = nil
        }

        upload
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .scan([ActivitySummary]()) { [weak self] previousActivitySummaries, currentActivitySummaries in
//                guard currentActivitySummaries.last != self?.activitySummary else { return [] }
//                guard previousActivitySummaries != currentActivitySummaries else { return [] }
                return currentActivitySummaries
            }
            .filter(\.isNotEmpty)
            .sinkAsync { [weak self] activitySummaries in
                guard let self = self else { return }
                try await self.upload(activitySummaries: activitySummaries)
                try await self.competitionsManager.updateStandings()
            }
            .store(in: &cancellables)

        query
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sinkAsync { [weak self] in try await self?.requestActivitySummaries() }
            .store(in: &cancellables)

        healthKitManager.registerBackgroundDeliveryReceiver(self)
        healthKitManager.registerForBackgroundDelivery()
    }

    // MARK: - Public Methods

    override func update() async throws {
        query.send()
    }

    // MARK: - Private Methods

    /// Don't call this directly, call `query` instead
    private func requestActivitySummaries() async throws {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let now = Calendar.current.date(from: components) ?? .now
        let yesterday = now.addingTimeInterval(-1.days)
        let tomorrow = now.addingTimeInterval(1.days)

        let dateInterval = competitionsManager.competitions
            .filter { $0.isActive && $0.participants.contains(user.id) }
            .reduce(DateInterval(start: yesterday, end: tomorrow)) { dateInterval, competition in
                .init(
                    start: [dateInterval.start, competition.start, yesterday].min() ?? yesterday,
                    end: [dateInterval.end, competition.end, tomorrow].max() ?? tomorrow
                )
            }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKActivitySummaryQuery(predicate: self.predicate(for: dateInterval)) { [weak self] query, hkActivitySummaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let activitySummaries = hkActivitySummaries?.map(\.activitySummary) ?? []
                self?.upload.send(activitySummaries)
                DispatchQueue.main.async { [weak self] in
                    self?.activitySummary = activitySummaries.first(where: \.date.isToday)
                }

                continuation.resume()
            }

            healthKitManager.execute(query)
        }
    }

    /// Don't call this directly, call `upload` instead
    private func upload(activitySummaries: [ActivitySummary]) async throws {
        let batch = database.batch()
        try activitySummaries
            .forEach { activitySummary in
                let documentId = DateFormatter.dateDashed.string(from: activitySummary.date)
                let document = database.document("users/\(user.id)/activitySummaries/\(documentId)")
                let _ = try batch.setDataEncodable(activitySummary, forDocument: document)
            }
        try await batch.commit()
    }

    private func predicate(for dateInterval: DateInterval) -> NSPredicate {
        let calendar = Calendar.current
        let units: Set<Calendar.Component> = [.day, .month, .year, .era]
        var startDateComponents = calendar.dateComponents(units, from: dateInterval.start)
        startDateComponents.calendar = calendar
        var endDateComponents = calendar.dateComponents(units, from: dateInterval.end)
        endDateComponents.calendar = calendar
        return HKQuery.predicate(forActivitySummariesBetweenStart: startDateComponents, end: endDateComponents)
    }
}

extension ActivitySummaryManager: HealthKitBackgroundDeliveryReceiving {
    func trigger() {
        query.send(())
    }
}
