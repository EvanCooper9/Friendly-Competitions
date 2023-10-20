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

            let permissionTypes = scoringModel.requiredPermissions
                .compactMap { permission in
                    switch permission {
                    case .health(let healthKitPermission):
                        return healthKitPermission
                    case .notifications:
                        return nil
                    }
                }

            switch scoringModel {
            case .activityRingCloseCount, .percentOfGoals, .rawNumbers:
                return self.healthKitBanner(for: permissionTypes,
                                            dataPublisher: dependency.activitySummaryManager.activitySummaries(in: dateInterval),
                                            healthKitManager: dependency.healthKitManager)
            case .workout(let workoutType, let metrics):
                return self.healthKitBanner(for: permissionTypes,
                                            dataPublisher: dependency.workoutManager.workouts(of: workoutType, with: metrics, in: dateInterval),
                                            healthKitManager: dependency.healthKitManager)
            case .stepCount:
                return self.healthKitBanner(for: permissionTypes,
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
        permissions
            .map { permission in
                healthKitManager.shouldRequest([permission])
                    .catchErrorJustReturn(false)
                    .flatMapLatest { shouldRequest -> AnyPublisher<Banner?, Never> in
                        guard !shouldRequest else {
                            return .just(.healthKitPermissionsMissing(permissions: [permission]))
                        }
                        return dataPublisher
                            .map { $0.isEmpty ? .healthKitDataMissing(dataType: [permission]) : nil }
                            .catchErrorJustReturn(.healthKitDataMissing(dataType: [permission]))
                            .eraseToAnyPublisher()
                    }
            }
            .combineLatest()
            .map { banners in
                var missingPermissions = [HealthKitPermissionType]()
                var missingData = [HealthKitPermissionType]()

                banners.forEach { banner in
                    switch banner {
                    case .healthKitPermissionsMissing(let permissions):
                        missingPermissions.append(contentsOf: permissions)
                    case .healthKitDataMissing(let permissions):
                        missingData.append(contentsOf: permissions)
                    default:
                        break
                    }
                }

                if missingPermissions.isNotEmpty {
                    return Banner.healthKitPermissionsMissing(permissions: missingPermissions)
                } else if missingData.isNotEmpty {
                    return Banner.healthKitDataMissing(dataType: missingData)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
}
