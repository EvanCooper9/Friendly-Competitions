import Firebase
import FirebaseFirestore
import Foundation
import HealthKit
import Resolver

class AnyActivitySummaryManager: ObservableObject {
    @Published var activitySummary: HKActivitySummary?
    func setup(with user: User) {}
}

final class ActivitySummaryManager: AnyActivitySummaryManager {

    // MARK: - Private Properties

    @Injected private var healthKitManager: AnyHealthKitManager
    @Injected private var database: Firestore

    private var user: User!

    // MARK: - Public Methods

    override func setup(with user: User) {
        self.user = user
        healthKitManager.registerBackgroundDeliveryReceiver(self)
        healthKitManager.registerForBackgroundDelivery()
    }

    // MARK: - Private Methods

    private func requestActivitySummaries() async throws {

        try Task.checkCancellation()

        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let now = Calendar.current.date(from: components) ?? .now
        let yesterday = now.addingTimeInterval(-1.days)
        let tomorrow = now.addingTimeInterval(1.days)

        let dateInterval = try await database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .getDocuments()
            .documents
            .decoded(asArrayOf: Competition.self)
            .filter { $0.isActive && !$0.pendingParticipants.contains(user.id) }
            .reduce(DateInterval(start: yesterday, end: tomorrow)) { dateInterval, competition in
                .init(
                    start: [dateInterval.start, competition.start, yesterday].min() ?? yesterday,
                    end: [dateInterval.end, competition.end, tomorrow].max() ?? tomorrow
                )
            }

        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKActivitySummaryQuery(predicate: self.predicate(for: dateInterval)) { [weak self] query, hkActivitySummaries, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                Task {
                    do {
                        try Task.checkCancellation()
                        let activitySummary = hkActivitySummaries?.first(where: \.isToday)
                        DispatchQueue.main.async {
                            self.activitySummary = activitySummary
                        }
                        try await self.upload(activitySummaries: hkActivitySummaries ?? [])
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            healthKitManager.execute(query)
        }
    }

    private func upload(activitySummaries: [HKActivitySummary]) async throws {
        let batch = database.batch()
        try activitySummaries
            .map(\.activitySummary)
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
    func trigger() async throws {
        try await requestActivitySummaries()
    }
}
