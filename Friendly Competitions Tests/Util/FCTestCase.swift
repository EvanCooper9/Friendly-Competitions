import CombineSchedulers
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

class FCTestCase: XCTestCase {

    let activitySummaryCache = ActivitySummaryCacheMock()
    let api = APIMock()
    let appServices = [AppService]()
    let appState = AppStateProvidingMock()
    let activitySummaryManager = ActivitySummaryManagingMock()
    let analyticsManager = AnalyticsManagingMock()
    let auth = AuthProvidingMock()
    let authenticationCache = AuthenticationCacheMock()
    let authenticationManager = AuthenticationManagingMock()
    let competitionCache = CompetitionCacheMock()
    let competitionsManager = CompetitionsManagingMock()
    let database = DatabaseMock()
    let environmentCache = EnvironmentCacheMock()
    let environmentManager = EnvironmentManagingMock()
    let featureFlagManager = FeatureFlagManagingMock()
    let friendsManager = FriendsManagingMock()
    let healthKitManager = HealthKitManagingMock()
    let healthStore = HealthStoringMock()
    let notificationsManager = NotificationsManagingMock()
    let searchClient = SearchClientMock()
    let searchManager = SearchManagingMock()
    let scheduler = TestSchedulerOf<RunLoop>(now: .init(.now))
    let signInWithAppleProvider = SignInWithAppleProvidingMock()
    let stepCountManager = StepCountManagingMock()
    let storageManager = StorageManagingMock()
    let premiumManager = PremiumManagingMock()
    let userManager = UserManagingMock()
    let workoutManager = WorkoutManagingMock()

    var cancellables = Cancellables()

    private var retainedObjects = [Any]()

    override func setUp() {
        super.setUp()
        register()
    }

    override func tearDown() {
        super.tearDown()
        retainedObjects = []
    }

    private func register() {
        Container.shared.activitySummaryCache.register { self.activitySummaryCache }
        Container.shared.activitySummaryManager.register { self.activitySummaryManager }
        Container.shared.analyticsManager.register { self.analyticsManager }
        Container.shared.api.register { self.api }
        Container.shared.appServices.register { self.appServices }
        Container.shared.appState.register { self.appState }
        Container.shared.auth.register { self.auth }
        Container.shared.authenticationCache.register { self.authenticationCache }
        Container.shared.authenticationManager.register { self.authenticationManager }
        Container.shared.competitionCache.register { self.competitionCache }
        Container.shared.competitionsManager.register { self.competitionsManager }
        Container.shared.database.register { self.database }
        Container.shared.environmentCache.register { self.environmentCache }
        Container.shared.environmentManager.register { self.environmentManager }
        Container.shared.featureFlagManager.register { self.featureFlagManager }
        Container.shared.friendsManager.register { self.friendsManager }
        Container.shared.healthKitManager.register { self.healthKitManager }
        Container.shared.healthStore.register { self.healthStore }
        Container.shared.notificationsManager.register { self.notificationsManager }
        Container.shared.premiumManager.register { self.premiumManager }
        Container.shared.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        Container.shared.searchClient.register { self.searchClient }
        Container.shared.searchManager.register { self.searchManager }
        Container.shared.stepCountManager.register { self.stepCountManager }
        Container.shared.signInWithAppleProvider.register { self.signInWithAppleProvider }
        Container.shared.storageManager.register { self.storageManager }
        Container.shared.userManager.register { self.userManager }
        Container.shared.workoutManager.register { self.workoutManager }
    }

    func retainDuringTest(_ object: Any) {
        retainedObjects.append(object)
    }
}
