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

    private var _container = Container()
    var container: Container { _container }

    override func setUp() {
        super.setUp()
        _container = .init()
        Container.shared = _container
        register()
    }

    private func register() {
        container.activitySummaryCache.register { self.activitySummaryCache }
        container.activitySummaryManager.register { self.activitySummaryManager }
        container.analyticsManager.register { self.analyticsManager }
        container.api.register { self.api }
        container.appServices.register { self.appServices }
        container.appState.register { self.appState }
        container.auth.register { self.auth }
        container.authenticationCache.register { self.authenticationCache }
        container.authenticationManager.register { self.authenticationManager }
        container.competitionCache.register { self.competitionCache }
        container.competitionsManager.register { self.competitionsManager }
        container.database.register { self.database }
        container.environmentCache.register { self.environmentCache }
        container.environmentManager.register { self.environmentManager }
        container.friendsManager.register { self.friendsManager }
        container.healthKitManager.register { self.healthKitManager }
        container.healthStore.register { self.healthStore }
        container.notificationsManager.register { self.notificationsManager }
        container.premiumManager.register { self.premiumManager }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.searchClient.register { self.searchClient }
        container.searchManager.register { self.searchManager }
        container.stepCountManager.register { self.stepCountManager }
        container.signInWithAppleProvider.register { self.signInWithAppleProvider }
        container.storageManager.register { self.storageManager }
        container.userManager.register { self.userManager }
        container.workoutManager.register { self.workoutManager }
    }
}
