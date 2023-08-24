import Combine
import CombineExt
import Factory
import Foundation

extension Competition {

    private final class BannerDependency {
        @Injected(\.activitySummaryManager) var activitySummaryManager
        @Injected(\.healthKitManager) var healthKitManager
        @Injected(\.notificationsManager) var notificationsManager
        @Injected(\.stepCountManager) var stepCountManager
        @Injected(\.userManager) var userManager
        @Injected(\.workoutManager) var workoutManager
    }

    var banners: AnyPublisher<[Banner], Never> {
        let dependency = BannerDependency()

        guard participants.contains(dependency.userManager.user.id) else { return .just([]) }

        let dateInterval = DateInterval(start: start, end: end)

        let healthKitBanner: AnyPublisher<Banner?, Never> = {
            guard isActive else { return .just(nil) }
            switch scoringModel {
            case .activityRingCloseCount, .percentOfGoals, .rawNumbers:
                return self.healthKitBanner(for: [HealthKitPermissionType.activitySummaryType],
                                            dataPublisher: dependency.activitySummaryManager.activitySummaries(in: dateInterval),
                                            healthKitManager: dependency.healthKitManager)
            case .workout(let workoutType, let metrics):
                let permissionTypes = metrics.compactMap { $0.permission(for: workoutType) }
                return self.healthKitBanner(for: permissionTypes,
                                            dataPublisher: dependency.workoutManager.workouts(of: workoutType, with: metrics, in: dateInterval),
                                            healthKitManager: dependency.healthKitManager)
            case .stepCount:
                return self.healthKitBanner(for: [.stepCount],
                                            dataPublisher: dependency.stepCountManager.stepCounts(in: dateInterval),
                                            healthKitManager: dependency.healthKitManager)
            }
        }()

        let notificationsBanner = dependency.notificationsManager
            .permissionStatus()
            .map { permissionStatus -> Banner? in
                switch permissionStatus {
                case .authorized, .done:
                    return nil
                case .denied:
                    return .notificationPermissionsDenied
                case .notDetermined:
                    return .notificationPermissionsMissing
                }
            }
            .eraseToAnyPublisher()

        return [healthKitBanner, notificationsBanner]
            .combineLatest()
            .compactMapMany { $0 }
            .eraseToAnyPublisher()
    }

    private func healthKitBanner<Data>(for permissions: [HealthKitPermissionType], dataPublisher: AnyPublisher<[Data], Error>, healthKitManager: HealthKitManaging) -> AnyPublisher<Banner?, Never> {
        return healthKitManager.shouldRequest(permissions)
            .catchErrorJustReturn(false)
            .flatMapLatest { shouldRequest -> AnyPublisher<Banner?, Never> in
                guard !shouldRequest else {
                    return .just(.healthKitPermissionsMissing)
                }
                return dataPublisher
                    .map { $0.isEmpty ? .healthKitDataMissing : nil }
                    .catchErrorJustReturn(.healthKitDataMissing)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
