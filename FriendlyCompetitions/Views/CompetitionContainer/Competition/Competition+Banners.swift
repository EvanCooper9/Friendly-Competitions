import Combine
import CombineExt
import Factory
import Foundation

extension Competition {

    var banners: AnyPublisher<[Banner], Never> {

        let activitySummaryManager = Container.shared.activitySummaryManager.resolve()
        let featureFlagManager = Container.shared.featureFlagManager.resolve()
        let healthKitManager = Container.shared.healthKitManager.resolve()
        let notificationsManager = Container.shared.notificationsManager.resolve()
        let stepCountManager = Container.shared.stepCountManager.resolve()
        let userManager = Container.shared.userManager.resolve()
        let workoutManager = Container.shared.workoutManager.resolve()

        guard participants.contains(userManager.user.id) else { return .just([]) }

        let dateInterval = DateInterval(start: start, end: end)

        let healthKitBanner: AnyPublisher<Banner?, Never> = {
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
                                            dataPublisher: activitySummaryManager.activitySummaries(in: dateInterval),
                                            healthKitManager: healthKitManager)
            case .workout(let workoutType, let metrics):
                return self.healthKitBanner(for: permissionTypes,
                                            dataPublisher: workoutManager.workouts(of: workoutType, with: metrics, in: dateInterval),
                                            healthKitManager: healthKitManager)
            case .stepCount:
                return self.healthKitBanner(for: permissionTypes,
                                            dataPublisher: stepCountManager.stepCounts(in: dateInterval),
                                            healthKitManager: healthKitManager)
            }
        }()

        let notificationsBanner = notificationsManager
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

        let calculatingBanner = Just(())
            .map { _ -> Banner? in
                let gracePeriod = featureFlagManager.value(forDouble: .dataUploadGracePeriodHours).hours
                guard ended && canUploadData(gracePeriod: gracePeriod) else { return nil }
                return .competitionResultsCalculating(competition: self)
            }
            .eraseToAnyPublisher()

        return [healthKitBanner, notificationsBanner, calculatingBanner]
            .combineLatest()
            .compactMapMany { $0 }
            .eraseToAnyPublisher()
    }

    private func healthKitBanner<Data>(for permissions: [HealthKitPermissionType], dataPublisher: AnyPublisher<[Data], Error>, healthKitManager: HealthKitManaging) -> AnyPublisher<Banner?, Never> {
        healthKitManager.permissionsChanged
            .mapToValue(permissions)
            .flatMapLatest { permissions in
                permissions.map { permission in
                    healthKitManager.shouldRequest([permission])
                        .catchErrorJustReturn(false)
                        .flatMapLatest { shouldRequest -> AnyPublisher<Banner?, Never> in
                            if shouldRequest {
                                return .just(.healthKitPermissionsMissing(permissions: [permission]))
                            } else if isActive {
                                return dataPublisher
                                    .map { $0.isEmpty ? .healthKitDataMissing(competition: self, dataType: [permission]) : nil }
                                    .catchErrorJustReturn(.healthKitDataMissing(competition: self, dataType: [permission]))
                                    .eraseToAnyPublisher()
                            } else {
                                return .just(nil)
                            }
                        }
                }
                .combineLatest()
            }
            .map { banners in
                var missingPermissions = [HealthKitPermissionType]()
                var missingData = [HealthKitPermissionType]()

                banners.forEach { banner in
                    switch banner {
                    case .healthKitPermissionsMissing(let permissions):
                        missingPermissions.append(contentsOf: permissions)
                    case .healthKitDataMissing(_, let permissions):
                        missingData.append(contentsOf: permissions)
                    default:
                        break
                    }
                }

                if missingPermissions.isNotEmpty {
                    return Banner.healthKitPermissionsMissing(permissions: missingPermissions)
                } else if missingData.isNotEmpty {
                    return Banner.healthKitDataMissing(competition: self, dataType: missingData)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
}
