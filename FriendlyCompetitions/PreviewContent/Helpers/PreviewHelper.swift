import CombineSchedulers
import Factory
import FCKitMocks
import SwiftUI

#if DEBUG
private enum Dependencies {
    static let api = APIMock()
    static let appServices = [AppService]()
    static let appState = AppStateProvidingMock()
    static let activitySummaryManager = ActivitySummaryManagingMock()
    static let analyticsManager = AnalyticsManagingMock()
    static let authenticationManager = AuthenticationManagingMock()
    static let backgroundRefreshManager = BackgroundRefreshManagingMock()
    static let bannerManager = BannerManagingMock()
    static let competitionsManager = CompetitionsManagingMock()
    static let featureFlagManager = FeatureFlagManagingMock()
    static let friendsManager = FriendsManagingMock()
    static let healthKitManager = HealthKitManagingMock()
    static let healthStore = HealthStoringMock()
    static let notificationsManager = NotificationsManagingMock()
    static let searchManager = SearchManagingMock()
    static let scheduler = AnySchedulerOf<RunLoop>.main
    static let stepCountManager = StepCountManagingMock()
    static let storageManager = StorageManagingMock()
    static let userManager = UserManagingMock()
    static let workoutManager = WorkoutManagingMock()

    static func register() {
        Container.shared.reset()
        Container.shared.api.register { api }
        Container.shared.appServices.register { appServices }
        Container.shared.appState.register { appState }
        Container.shared.activitySummaryManager.register { activitySummaryManager }
        Container.shared.analyticsManager.register { analyticsManager }
        Container.shared.authenticationManager.register { authenticationManager }
        Container.shared.backgroundRefreshManager.register { backgroundRefreshManager }
        Container.shared.bannerManager.register { bannerManager }
        Container.shared.competitionsManager.register { competitionsManager }
        Container.shared.featureFlagManager.register { featureFlagManager }
        Container.shared.friendsManager.register { friendsManager }
        Container.shared.healthKitManager.register { healthKitManager }
        Container.shared.healthStore.register { healthStore }
        Container.shared.notificationsManager.register { notificationsManager }
        Container.shared.searchManager.register { searchManager }
        Container.shared.scheduler.register { scheduler }
        Container.shared.stepCountManager.register { stepCountManager }
        Container.shared.storageManager.register { storageManager }
        Container.shared.userManager.register { userManager }
        Container.shared.workoutManager.register { workoutManager }
    }

    static func baseSetupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        activitySummaryManager.activitySummariesInReturnValue = .just([])

        appState.deepLink = .just(nil)
        appState.didBecomeActive = .just(false)
        appState.isActive = .just(true)

        authenticationManager.emailVerified = .just(true)
        authenticationManager.loggedIn = .just(true)

        bannerManager.banners = .just([])

        backgroundRefreshManager.status = .just(.available)

        competitionsManager.competitions = .just([])
        competitionsManager.competitionPublisherForClosure = { _ in .never() }
        competitionsManager.invitedCompetitions = .just([])
        competitionsManager.standingsPublisherForLimitReturnValue = .just([])
        competitionsManager.standingsForResultIDReturnValue = .just([])
        competitionsManager.appOwnedCompetitions = .just([.mockPublic])
        competitionsManager.resultsForReturnValue = .just([])

        featureFlagManager.valueForBoolFeatureFlagFeatureFlagBoolBoolReturnValue = false
        featureFlagManager.valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReturnValue = 0
        featureFlagManager.valueForStringFeatureFlagFeatureFlagStringStringReturnValue = ""

        friendsManager.friends = .just([])
        friendsManager.friendActivitySummaries = .just([:])
        friendsManager.friendRequests = .just([])

        healthKitManager.permissionsChanged = .just(())

        searchManager.searchForCompetitionsByNameReturnValue = .just([])
        searchManager.searchForUsersByNameReturnValue = .just([])
        searchManager.searchForUsersWithIDsReturnValue = .just([])

        storageManager.getReturnValue = .just(.init())

        userManager.user = .evan
        userManager.userPublisher = .just(.evan)
        userManager.updateWithReturnValue = .just(())

        workoutManager.workoutsOfWithInReturnValue = .just([])
    }
}

extension PreviewProvider {
    static var api: APIMock { Dependencies.api }
    static var appState: AppStateProvidingMock { Dependencies.appState }
    static var activitySummaryManager: ActivitySummaryManagingMock { Dependencies.activitySummaryManager }
    static var analyticsManager: AnalyticsManagingMock { Dependencies.analyticsManager }
    static var authenticationManager: AuthenticationManagingMock { Dependencies.authenticationManager }
    static var backgroundRefreshManager: BackgroundRefreshManagingMock { Dependencies.backgroundRefreshManager }
    static var bannerManager: BannerManagingMock { Dependencies.bannerManager }
    static var competitionsManager: CompetitionsManagingMock { Dependencies.competitionsManager }
    static var featureFlagManager: FeatureFlagManagingMock { Dependencies.featureFlagManager }
    static var friendsManager: FriendsManagingMock { Dependencies.friendsManager }
    static var healthKitManager: HealthKitManagingMock { Dependencies.healthKitManager }
    static var healthStore: HealthStoringMock { Dependencies.healthStore }
    static var notificationsManager: NotificationsManagingMock { Dependencies.notificationsManager }
    static var searchManager: SearchManagingMock { Dependencies.searchManager }
    static var scheduler: AnySchedulerOf<RunLoop> { Dependencies.scheduler }
    static var stepCountManager: StepCountManagingMock { Dependencies.stepCountManager }
    static var storageManager: StorageManagingMock { Dependencies.storageManager }
    static var userManager: UserManagingMock { Dependencies.userManager }
    static var workoutManager: WorkoutManagingMock { Dependencies.workoutManager }

    static func setupMocks(_ setupMocks: (() -> Void)? = nil) {
        Dependencies.register()
        Dependencies.baseSetupMocks()
        setupMocks?()
    }
}

extension View {
    func setupMocks(_ setupMocks: @escaping () -> Void = {}) -> some View {
        Dependencies.register()
        Dependencies.baseSetupMocks()
        setupMocks()
        return self
    }
}
#endif
