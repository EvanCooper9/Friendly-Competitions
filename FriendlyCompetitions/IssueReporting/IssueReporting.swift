import Combine
import Factory
import FCKit
import Foundation

protocol IssueReporting {
    func report(title: String, description: String) -> any Publisher<Void, Error>
}

final class IssueReporter: IssueReporting {

    @Injected(\.activitySummaryManager) private var activitySummaryManager: ActivitySummaryManaging
    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.api) private var api: API
    @Injected(\.backgroundRefreshManager) private var backgroundRefereshManager: BackgroundRefreshManaging
    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.healthKitManager) private var healthKitManager: HealthKitManaging
    @Injected(\.storageManager) private var storageManager: StorageManaging
    @Injected(\.userManager) private var userManager: UserManaging

    func report(title: String, description: String) -> any Publisher<Void, Error> {
        Publishers
            .CombineLatest4(
                activitySummaries().eraseToAnyPublisher(),
                backgroundRefreshStatus().eraseToAnyPublisher(),
                competitions().eraseToAnyPublisher(),
                healthKitPermissions().eraseToAnyPublisher()
            )
            .first()
            .setFailureType(to: Error.self)
            .flatMapLatest { [analyticsManager, featureFlagManager, storageManager, userManager] result in
                let (activitySummaries, backgroundRefreshStatus, competitions, healthKitPermissions) = result
                do {
                    let issue = Issue(
                        title: title,
                        description: description,
                        user: userManager.user,
                        appIdendifier: Bundle.main.bundleIdentifier ?? "",
                        appVersion: Bundle.main.version,
                        flags: featureFlagManager.flags(),
                        analyticEvents: analyticsManager.events,
                        competitions: competitions,
                        healthKitPermissions: healthKitPermissions,
                        backgroundRefreshStatus: backgroundRefreshStatus,
                        activitySummaries: activitySummaries
                    )

                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try JSONSerialization.data(withJSONObject: issue.jsonDictionary(encoder: encoder), options: .sortedKeys)
                    return storageManager.set("issues/\(UUID().uuidString).json", data: data)
                } catch {
                    return AnyPublisher<Void, Error>.error(error)
                }
            }
    }

    // MARK: - Private

    private struct Issue: Encodable {
        let date = Date()
        let locale = Locale.current
        let title: String
        let description: String
        let user: User
        let appIdendifier: String
        let appVersion: String
        let flags: [String: String]
        let analyticEvents: [AnalyticEventWrapper]
        let competitions: [Competition.ID]
        let healthKitPermissions: [HealthKitPermissionType: Bool]
        let backgroundRefreshStatus: BackgroundRefreshStatus
        let activitySummaries: [ActivitySummary]
    }

    private func activitySummaries() -> any Publisher<[ActivitySummary], Never> {
        competitionsManager.competitions
            .filterMany { competition in
                switch competition.scoringModel {
                case .activityRingCloseCount,
                     .percentOfGoals:
                    return true
                case .rawNumbers,
                     .stepCount,
                     .workout:
                    return false
                }
            }
            .map(\.dateInterval)
            .flatMapLatest { [activitySummaryManager] dateInterval -> AnyPublisher<[ActivitySummary], Never> in
                guard let dateInterval else { return Just([]).eraseToAnyPublisher() }
                return activitySummaryManager
                    .activitySummaries(in: dateInterval)
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }
    }

    private func backgroundRefreshStatus() -> any Publisher<BackgroundRefreshStatus, Never> {
        backgroundRefereshManager
            .status
    }

    private func competitions() -> any Publisher<[Competition.ID], Never> {
        competitionsManager
            .competitions
            .mapMany(\.id)
    }

    private func healthKitPermissions() -> any Publisher<[HealthKitPermissionType: Bool], Never> {
        HealthKitPermissionType
            .allCases
            .map { permission in
                healthKitManager
                    .shouldRequest([permission])
                    .catchErrorJustReturn(false)
                    .map { (permission, !$0) }
            }
            .combineLatest()
            .map(Dictionary.init(uniqueKeysWithValues:))
    }
}

extension FeatureFlagManaging {
    func flags() -> [String: String] {
        var flags = [String: String]()
        FeatureFlagBool.allCases.forEach { flags[$0.stringValue] = value(forBool: $0).description }
        FeatureFlagString.allCases.forEach { flags[$0.stringValue] = value(forString: $0).description }
        FeatureFlagDouble.allCases.forEach { flags[$0.stringValue] = value(forDouble: $0).description }
        return flags
    }
}
