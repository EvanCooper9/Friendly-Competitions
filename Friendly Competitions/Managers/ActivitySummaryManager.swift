import FirebaseFirestore
import Foundation
import HealthKit
import Resolver

protocol ActivitySummaryManaging {
    func addHandler(_ handler: @escaping ([HKActivitySummary]) -> Void)
    func registerForBackgroundDelivery()
}

final class ActivitySummaryManager: ActivitySummaryManaging {

    private let healthStore = HKHealthStore()

    @LazyInjected private var healthKitManager: HealthKitManaging
    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    private var activitySummaries = [HKActivitySummary]() {
        didSet {
            handlers.forEach { $0(activitySummaries) }
        }
    }

    private var handlers = [([HKActivitySummary]) -> Void]()
    private var observerQueries = [HKObserverQuery]()
    private var queries = [HKQuery]()

    private var healthStoreQueryTask: Task<[ActivitySummary], Error>?

    // MARK: - Public Methods

    func addHandler(_ handler: @escaping ([HKActivitySummary]) -> Void) {
        handlers.append(handler)
        Task { try? await requestActivitySummaries() }
    }

    func registerForBackgroundDelivery() {
        healthKitManager.registerReceiver(self)
    }

    // MARK: - Private Methods

    private func requestActivitySummaries() async throws {

        try Task.checkCancellation()

        let dateInterval = try await database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .getDocuments()
            .documents
            .decoded(asArrayOf: Competition.self)
            .filter { $0.isActive && !$0.pendingParticipants.contains(user.id) }
            .reduce(DateInterval()) { dateInterval, competition in
                let yesterday = Date.now.addingTimeInterval(-1.days)
                let tomorrow = Date.now.addingTimeInterval(1.days)
                return .init(
                    start: [dateInterval.start, competition.start, yesterday].min() ?? yesterday,
                    end: [dateInterval.end, competition.end, tomorrow].max() ?? tomorrow
                )
            }

        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKActivitySummaryQuery(predicate: self.predicate(for: dateInterval)) { query, hkActivitySummaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                Task {
                    do {
                        try Task.checkCancellation()
                        self.activitySummaries = hkActivitySummaries ?? []
                        try await self.uploadActivitySummaries()
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            self.healthStore.execute(query)
        }
    }

    private func updateHandlers() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.handlers.forEach { $0(self.activitySummaries) }
        }
    }

    private func uploadActivitySummaries() async throws {
        let batch = database.batch()
        try activitySummaries
            .map(\.activitySummary)
            .forEach { activitySummary in
                let documentId = activitySummary.date.formatted(date: .numeric, time: .omitted)
                let document = self.database.document("users/\(self.user.id)/activitySummaries/\(documentId)")
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
    func trigger() async throws {
        try await self.requestActivitySummaries()
    }
}
