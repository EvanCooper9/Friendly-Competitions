import Resolver
import SwiftUI

fileprivate struct Container {
    static let appState = AppState()
    static let activitySummaryManager = AnyActivitySummaryManager()
    static let analyticsManager = AnyAnalyticsManager()
    static let authenticationManager = AnyAuthenticationManager()
    static let competitionsManager = CompetitionsManagingMock()
    static let friendsManager = AnyFriendsManager()
    static let healthKitManager = AnyHealthKitManager()
    static let permissionsManager = AnyPermissionsManager()
    static let storageManager = AnyStorageManager()
    static let userManager = AnyUserManager(user: .evan)
    
    static func registerDependencies() {
        Resolver.register { Container.appState }.scope(.application)
        Resolver.register { Container.activitySummaryManager }.scope(.application)
        Resolver.register { Container.analyticsManager }.scope(.application)
        Resolver.register { Container.authenticationManager }.scope(.application)
        Resolver.register { Container.competitionsManager }.scope(.application)
        Resolver.register { Container.friendsManager }.scope(.application)
        Resolver.register { Container.healthKitManager }.scope(.application)
        Resolver.register { Container.permissionsManager }.scope(.application)
        Resolver.register { Container.storageManager }.scope(.application)
        Resolver.register { Container.userManager }.scope(.application)
    }
}

extension PreviewProvider {
    static var appState: AppState { Container.appState }
    static var activitySummaryManager: AnyActivitySummaryManager { Container.activitySummaryManager }
    static var analyticsManager: AnyAnalyticsManager { Container.analyticsManager }
    static var authenticationManager: AnyAuthenticationManager { Container.authenticationManager }
    static var competitionsManager: CompetitionsManagingMock { Container.competitionsManager }
    static var friendsManager: AnyFriendsManager { Container.friendsManager }
    static var healthKitManager: AnyHealthKitManager { Container.healthKitManager }
    static var permissionsManager: AnyPermissionsManager { Container.permissionsManager }
    static var storageManager: AnyStorageManager { Container.storageManager }
    static var userManager: AnyUserManager { Container.userManager }
    
    static func registerDependencies() {
        Container.registerDependencies()
    }
}

extension View {
    func setupMocks(_ setupMocks: @escaping () -> Void = {}) -> some View {
        Container.registerDependencies()
        return self
            .environmentObject(Container.appState)
            .environmentObject(Container.activitySummaryManager)
            .environmentObject(Container.analyticsManager)
            .environmentObject(Container.friendsManager)
            .environmentObject(Container.healthKitManager)
            .environmentObject(Container.permissionsManager)
            .environmentObject(Container.storageManager)
            .environmentObject(Container.userManager)
            .onAppear(perform: setupMocks)
    }
}
