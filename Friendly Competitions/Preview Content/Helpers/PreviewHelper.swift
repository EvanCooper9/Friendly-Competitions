import Factory
import SwiftUI

#if DEBUG
fileprivate enum Dependencies {
    static let api = APIMock()
    static let appServices = [AppService]()
    static let appState = AppStateProvidingMock()
    static let activitySummaryManager = ActivitySummaryManagingMock()
    static let analyticsManager = AnalyticsManagingMock()
    static let authenticationManager = AuthenticationManagingMock()
    static let competitionsManager = CompetitionsManagingMock()
    static let friendsManager = FriendsManagingMock()
    static let healthKitManager = HealthKitManagingMock()
    static let permissionsManager = PermissionsManagingMock()
    static let searchManager = SearchManagingMock()
    static let storageManager = StorageManagingMock()
    static let premiumManager = PremiumManagingMock()
    static let userManager = UserManagingMock()
    static let workoutManager = WorkoutManagingMock()
    
    static func register() {
        let _ = Container.shared.api.register { api }
        let _ = Container.shared.appServices.register { appServices }
        let _ = Container.shared.appState.register { appState }
        let _ = Container.shared.activitySummaryManager.register { activitySummaryManager }
        let _ = Container.shared.analyticsManager.register { analyticsManager }
        let _ = Container.shared.authenticationManager.register { authenticationManager }
        let _ = Container.shared.competitionsManager.register { competitionsManager }
        let _ = Container.shared.friendsManager.register { friendsManager }
        let _ = Container.shared.healthKitManager.register { healthKitManager }
        let _ = Container.shared.permissionsManager.register { permissionsManager }
        let _ = Container.shared.searchManager.register { searchManager }
        let _ = Container.shared.storageManager.register { storageManager }
        let _ = Container.shared.premiumManager.register { premiumManager }
        let _ = Container.shared.userManager.register { userManager }
        let _ = Container.shared.workoutManager.register { workoutManager }
    }

    static func baseSetupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        activitySummaryManager.activitySummariesInReturnValue = .just([])
        
        appState.deepLink = .just(nil)

        authenticationManager.emailVerified = .just(true)
        authenticationManager.loggedIn = .just(true)

        competitionsManager.competitions = .just([])
        competitionsManager.competitionPublisherForClosure = { _ in .never() }
        competitionsManager.invitedCompetitions = .just([])
        competitionsManager.standingsPublisherForReturnValue = .just([])
        competitionsManager.standingsForResultIDReturnValue = .just([])
        competitionsManager.participantsForReturnValue = .just([])
        competitionsManager.appOwnedCompetitions = .just([.mockPublic])
        competitionsManager.resultsForReturnValue = .just([])
        competitionsManager.hasPremiumResults = .just(false)
        
        friendsManager.friends = .just([])
        friendsManager.friendActivitySummaries = .just([:])
        friendsManager.friendRequests = .just([])

        searchManager.searchForCompetitionsByNameReturnValue = .just([])
        searchManager.searchForUsersByNameReturnValue = .just([])
        
        storageManager.dataForReturnValue = .just(.init())
        
        premiumManager.premium = .just(nil)
        premiumManager.products = .just([])
        premiumManager.purchaseReturnValue = .just(())
        
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
    static var competitionsManager: CompetitionsManagingMock { Dependencies.competitionsManager }
    static var friendsManager: FriendsManagingMock { Dependencies.friendsManager }
    static var healthKitManager: HealthKitManagingMock { Dependencies.healthKitManager }
    static var permissionsManager: PermissionsManagingMock { Dependencies.permissionsManager }
    static var storageManager: StorageManagingMock { Dependencies.storageManager }
    static var premiumManager: PremiumManagingMock { Dependencies.premiumManager }
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
