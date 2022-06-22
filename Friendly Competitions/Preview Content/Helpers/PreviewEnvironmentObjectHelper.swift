import Resolver
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
        Resolver.register { Container.appState }.scope(.application)
        Resolver.register(ActivitySummaryManaging.self) { Container.activitySummaryManager }.scope(.application)
        Resolver.register(AnalyticsManaging.self) { Container.analyticsManager }.scope(.application)
        Resolver.register(AuthenticationManaging.self) { Container.authenticationManager }.scope(.application)
        Resolver.register(CompetitionsManaging.self) { Container.competitionsManager }.scope(.application)
        Resolver.register(FriendsManaging.self) { Container.friendsManager }.scope(.application)
        Resolver.register(HealthKitManaging.self) { Container.healthKitManager }.scope(.application)
        Resolver.register(PermissionsManaging.self) { Container.permissionsManager }.scope(.application)
        Resolver.register(StorageManaging.self) { Container.storageManager }.scope(.application)
        Resolver.register(UserManaging.self) {
            let userManager = Container.userManager
            userManager.user = .init(.evan)
            return userManager
        }.scope(.application)
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
}

extension View {
    func setupMocks(_ setupMocks: @escaping () -> Void = {}) -> some View {
        Container.registerDependencies()
        return self
            .onAppear(perform: setupMocks)
    }
}
