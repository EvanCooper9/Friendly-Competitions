import Factory
import SwiftUI

fileprivate enum Dependencies {
    static let appState = AppState()
    static let activitySummaryManager = ActivitySummaryManagingMock()
    static let analyticsManager = AnalyticsManagingMock()
    static let authenticationManager = AuthenticationManagingMock()
    static let competitionsManager = CompetitionsManagingMock()
    static let friendsManager = FriendsManagingMock()
    static let healthKitManager = HealthKitManagingMock()
    static let permissionsManager = PermissionsManagingMock()
    static let storageManager = StorageManagingMock()
    static let userManager = UserManagingMock()
    static let workoutManager = WorkoutManagingMock()
    
    static func register() {
        Container.appState.register { appState }
        Container.activitySummaryManager.register { activitySummaryManager }
        Container.analyticsManager.register { analyticsManager }
        Container.authenticationManager.register { authenticationManager }
        Container.competitionsManager.register { competitionsManager }
        Container.friendsManager.register { friendsManager }
        Container.healthKitManager.register { healthKitManager }
        Container.permissionsManager.register { permissionsManager }
        Container.storageManager.register { storageManager }
        Container.userManager.register { userManager }
    }

    static func baseSetupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        activitySummaryManager.updateReturnValue = .just(())

        authenticationManager.emailVerified = .just(true)
        authenticationManager.loggedIn = .just(true)

        competitionsManager.competitions = .just([.mock])
        competitionsManager.invitedCompetitions = .just([])
        competitionsManager.standings = .just([:])
        competitionsManager.participants = .just([:])
        competitionsManager.pendingParticipants = .just([:])
        competitionsManager.appOwnedCompetitions = .just([.mockPublic])
        competitionsManager.searchReturnValue = .just([.mockPublic, .mock])
        
        friendsManager.friends = .just([])
        friendsManager.friendActivitySummaries = .just([:])
        friendsManager.friendRequests = .just([])

        storageManager.dataForReturnValue = .just(.init())
        
        userManager.user = .evan
        userManager.userPublisher = .just(.evan)
        userManager.updateWithReturnValue = .just(())
        
        workoutManager.updateReturnValue = .just(())
    }
}

extension PreviewProvider {
    static var appState: AppState { Dependencies.appState }
    static var activitySummaryManager: ActivitySummaryManagingMock { Dependencies.activitySummaryManager }
    static var analyticsManager: AnalyticsManagingMock { Dependencies.analyticsManager }
    static var authenticationManager: AuthenticationManagingMock { Dependencies.authenticationManager }
    static var competitionsManager: CompetitionsManagingMock { Dependencies.competitionsManager }
    static var friendsManager: FriendsManagingMock { Dependencies.friendsManager }
    static var healthKitManager: HealthKitManagingMock { Dependencies.healthKitManager }
    static var permissionsManager: PermissionsManagingMock { Dependencies.permissionsManager }
    static var storageManager: StorageManagingMock { Dependencies.storageManager }
    static var userManager: UserManagingMock { Dependencies.userManager }
}

extension View {
    func setupMocks(_ setupMocks: @escaping () -> Void = {}) -> some View {
        Dependencies.register()
        Dependencies.baseSetupMocks()
        setupMocks()
        return self
    }
}
