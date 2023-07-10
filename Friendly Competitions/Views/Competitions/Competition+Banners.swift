import Combine
import CombineExt
import Foundation

extension Competition {
    func banners(activitySummaryManager: ActivitySummaryManaging, healthKitManager: HealthKitManaging, notificationsManager: NotificationsManaging, stepCountManager: StepCountManaging, workoutManager: WorkoutManaging) -> AnyPublisher<[Banner], Never> {
        let dateInterval = DateInterval(start: start, end: end)

        let healthKitBanner: AnyPublisher<Banner?, Never> = {
            switch scoringModel {
            case .activityRingCloseCount, .percentOfGoals, .rawNumbers:
                return self.healthKitBanner(for: [HealthKitPermissionType.activitySummaryType],
                                       dataPublisher: activitySummaryManager.activitySummaries(in: dateInterval),
                                       healthKitManager: healthKitManager)
            case .workout(let workoutType, let metrics):
                let permissionTypes = metrics.compactMap { $0.permission(for: workoutType) }
                return self.healthKitBanner(for: permissionTypes,
                                       dataPublisher: workoutManager.workouts(of: workoutType, with: metrics, in: dateInterval),
                                       healthKitManager: healthKitManager)
            case .stepCount:
                return self.healthKitBanner(for: [.stepCount],
                                       dataPublisher: stepCountManager.stepCounts(in: dateInterval),
                                       healthKitManager: healthKitManager)
            }
        }()

        let notificationsBanner = notificationsManager.permissionStatus()
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
                guard shouldRequest else { return .just(.healthKitPermissionsMissing) }
                return dataPublisher
                    .map { $0.isEmpty ? .healthKitDataMissing : nil }
                    .catchErrorJustReturn(.healthKitDataMissing)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
