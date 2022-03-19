import SwiftUI

fileprivate struct Container {
    static let appState = AppState()
    static let activitySummaryManager = AnyActivitySummaryManager()
    static let authenticationManager = AnyAuthenticationManager()
    static let competitionsManager = AnyCompetitionsManager()
    static let friendsManager = AnyFriendsManager()
    static let healthKitManager = AnyHealthKitManager()
    static let permissionsManager = AnyPermissionsManager()
    static let storageManager = AnyStorageManager()
    static let userManager = AnyUserManager(user: .evan)
}

extension PreviewProvider {
    static var activitySummaryManager: AnyActivitySummaryManager { Container.activitySummaryManager }
    static var authenticationManager: AnyAuthenticationManager { Container.authenticationManager }
    static var competitionsManager: AnyCompetitionsManager { Container.competitionsManager }
    static var friendsManager: AnyFriendsManager { Container.friendsManager }
    static var healthKitManager: AnyHealthKitManager { Container.healthKitManager }
    static var permissionsManager: AnyPermissionsManager { Container.permissionsManager }
    static var storageManager: AnyStorageManager { Container.storageManager }
    static var userManager: AnyUserManager { Container.userManager }
}

extension View {
    func withEnvironmentObjects(setupMocks: @escaping () -> Void = {}) -> some View {
        self
            .environmentObject(Container.appState)
            .environmentObject(Container.activitySummaryManager)
            .environmentObject(Container.authenticationManager)
            .environmentObject(Container.competitionsManager)
            .environmentObject(Container.friendsManager)
            .environmentObject(Container.healthKitManager)
            .environmentObject(Container.permissionsManager)
            .environmentObject(Container.storageManager)
            .environmentObject(Container.userManager)
            .onAppear(perform: setupMocks)
    }
}
