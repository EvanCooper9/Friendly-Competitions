import Combine
import ECKit
import Factory
import UIKit

final class ActivitySummaryInfoViewModel: ObservableObject {

    private enum Constants {
        static let permissionTypes: [HealthKitPermissionType] = [
            .activitySummaryType,
            .activeEnergy,
            .appleExerciseTime,
            .appleStandHour
        ]
    }

    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var showMissingActivitySummaryText = false
    @Published private(set) var loadingPermissionStatus = false
    @Published private(set) var shouldRequestPermissions = false

    // MARK: - Private Properties

    @LazyInjected(\.activitySummaryManager) private var activitySummaryManager
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.scheduler) private var scheduler

    private let requestPermissionsSubject = PassthroughSubject<Void, Error>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(source: ActivitySummaryInfoSource) {
        switch source {
        case .local:
            let activitySummary = activitySummaryManager.activitySummary
                .removeDuplicates()
                .receive(on: scheduler)

            activitySummary.assign(to: &$activitySummary)
            activitySummary.map(\.isNil).assign(to: &$showMissingActivitySummaryText)

            healthKitManager.shouldRequest(Constants.permissionTypes)
                .receive(on: scheduler)
                .isLoading(set: \.loadingPermissionStatus, on: self)
                .catchErrorJustReturn(false)
                .assign(to: &$shouldRequestPermissions)
        case .other(let activitySummary):
            self.activitySummary = activitySummary
        }

        requestPermissionsSubject
            .flatMapLatest(withUnretained: self) { $0.healthKitManager.request(Constants.permissionTypes) }
            .receive(on: scheduler)
            .sink(withUnretained: self) { $0.shouldRequestPermissions = false }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func requestPermissionsTapped() {
        requestPermissionsSubject.send()
    }

    func checkHealthAppTapped() {
        UIApplication.shared.openURL(.health)
    }
}
