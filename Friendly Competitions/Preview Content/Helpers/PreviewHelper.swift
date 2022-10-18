import Factory
import SwiftUI

fileprivate struct Container {
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
    
    static func registerDependencies() {
//        Resolver.registerViewModels()
//        Resolver.register { Container.appState }
//        Resolver.register(ActivitySummaryManaging.self) { Container.activitySummaryManager }
//        Resolver.register(AnalyticsManaging.self) { Container.analyticsManager }
//        Resolver.register(AuthenticationManaging.self) { Container.authenticationManager }
//        Resolver.register(CompetitionsManaging.self) { Container.competitionsManager }
//        Resolver.register(FriendsManaging.self) { Container.friendsManager }
//        Resolver.register(HealthKitManaging.self) { Container.healthKitManager }
//        Resolver.register(PermissionsManaging.self) { Container.permissionsManager }
//        Resolver.register(StorageManaging.self) { Container.storageManager }
//        Resolver.register(UserManaging.self) {
//            let userManager = Container.userManager
//            userManager.user = .init(.evan)
//            return userManager
//        }
    }

    static func baseSetupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        activitySummaryManager.updateReturnValue = .just(())

        authenticationManager.emailVerified = .just(true)
        authenticationManager.loggedIn = .just(true)

        competitionsManager.competitions = .just([.mock])
        competitionsManager.standings = .just([:])
        competitionsManager.participants = .just([:])
        competitionsManager.pendingParticipants = .just([:])
        competitionsManager.appOwnedCompetitions = .just([.mockPublic])
        competitionsManager.searchReturnValue = .just([.mockPublic, .mock])

        storageManager.dataForReturnValue = .init()
    }
}

extension PreviewProvider {
    static var appState: AppState { Container.appState }
    static var activitySummaryManager: ActivitySummaryManagingMock { Container.activitySummaryManager }
    static var analyticsManager: AnalyticsManagingMock { Container.analyticsManager }
    static var authenticationManager: AuthenticationManagingMock { Container.authenticationManager }
    static var competitionsManager: CompetitionsManagingMock { Container.competitionsManager }
    static var friendsManager: FriendsManagingMock { Container.friendsManager }
    static var healthKitManager: HealthKitManagingMock { Container.healthKitManager }
    static var permissionsManager: PermissionsManagingMock { Container.permissionsManager }
    static var storageManager: StorageManagingMock { Container.storageManager }
    static var userManager: UserManagingMock { Container.userManager }

    static func registerDependencies() {
        Container.registerDependencies()
    }
}

extension View {
    func setupMocks(_ setupMocks: @escaping () -> Void = {}) -> some View {
        Container.registerDependencies()
        Container.baseSetupMocks()
        setupMocks()
        return self
    }
}
