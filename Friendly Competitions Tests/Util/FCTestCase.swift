import Factory
import XCTest

@testable import Friendly_Competitions

class FCTestCase: XCTestCase {

    private var _container = Container()
    var container: Container { _container }

    override func setUp() {
        super.setUp()
        _container = .init()
        Container.shared = _container
        removeRegistrations()
    }

    private func removeRegistrations() {
        container.activitySummaryCache.register { fatalError("Use a mock") }
        container.activitySummaryManager.register { fatalError("Use a mock") }
        container.analyticsManager.register { fatalError("Use a mock") }
        container.api.register { fatalError("Use a mock") }
        container.appServices.register { fatalError("Use a mock") }
        container.appState.register { fatalError("Use a mock") }
        container.auth.register { fatalError("Use a mock") }
        container.authenticationCache.register { fatalError("Use a mock") }
        container.authenticationManager.register { fatalError("Use a mock") }
        container.competitionCache.register { fatalError("Use a mock") }
        container.competitionsManager.register { fatalError("Use a mock") }
        container.database.register { fatalError("Use a mock") }
        container.environmentCache.register { fatalError("Use a mock") }
        container.environmentManager.register { fatalError("Use a mock") }
        container.friendsManager.register { fatalError("Use a mock") }
        container.healthKitManager.register { fatalError("Use a mock") }
        container.healthKitDataHelperBuilder.register { fatalError("Use a mock") }
        container.healthStore.register { fatalError("Use a mock") }
        container.notificationsManager.register { fatalError("Use a mock") }
        container.premiumManager.register { fatalError("Use a mock") }
        container.scheduler.register { fatalError("Use a mock") }
        container.searchClient.register { fatalError("Use a mock") }
        container.searchManager.register { fatalError("Use a mock") }
        container.signInWithAppleProvider.register { fatalError("Use a mock") }
        container.storageManager.register { fatalError("Use a mock") }
        container.userManager.register { fatalError("Use a mock") }
        container.workoutCache.register { fatalError("Use a mock") }
        container.workoutManager.register { fatalError("Use a mock") }
    }
}
