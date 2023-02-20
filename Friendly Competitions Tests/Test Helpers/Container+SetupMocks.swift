import Factory

@testable import Friendly_Competitions

extension Container {
    private static let appStateMock = AppState()
    private static let activitySummaryManagerMock = ActivitySummaryManagingMock()
    private static let analyticsManagerMock = AnalyticsManagingMock()
    private static let authenticationManagerMock = AuthenticationManagingMock()
    private static let competitionsManagerMock = CompetitionsManagingMock()
    private static let friendsManagerMock = FriendsManagingMock()
    private static let healthKitManagerMock = HealthKitManagingMock()
    private static let permissionsManagerMock = PermissionsManagingMock()
    private static let searchManagerMock = SearchManagingMock()
    private static let storageManagerMock = StorageManagingMock()
    private static let premiumManagerMock = PremiumManagingMock()
    private static let userManagerMock = UserManagingMock()
    private static let workoutManagerMock = WorkoutManagingMock()
    
    static func setupMocks() {
        Container.appState.register { appStateMock }
        Container.activitySummaryManager.register { activitySummaryManagerMock }
        Container.analyticsManager.register { analyticsManagerMock }
        Container.authenticationManager.register { authenticationManagerMock }
        Container.competitionsManager.register { competitionsManagerMock }
        Container.friendsManager.register { friendsManagerMock }
        Container.healthKitManager.register { healthKitManagerMock }
        Container.permissionsManager.register { permissionsManagerMock }
        Container.searchManager.register { searchManagerMock }
        Container.storageManager.register { storageManagerMock }
        Container.premiumManager.register { premiumManagerMock }
        Container.userManager.register { userManagerMock }
        Container.workoutManager.register { workoutManagerMock }
    }
}
