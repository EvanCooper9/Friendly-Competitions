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

    // MARK: - Private Methods

    private func removeRegistrations() {
        container.api.register { fatalError("Use a mock") }
        container.appServices.register { fatalError("Use a mock") }
        container.appState.register { fatalError("Use a mock") }
        container.activitySummaryManager.register { fatalError("Use a mock") }
        container.analyticsManager.register { fatalError("Use a mock") }
        container.authenticationManager.register { fatalError("Use a mock") }
        container.competitionsManager.register { fatalError("Use a mock") }
        container.database.register { fatalError("Use a mock") }
        container.deepLinkManager.register { fatalError("Use a mock") }
        container.featureFlagManager.register { fatalError("Use a mock") }
        container.friendsManager.register { fatalError("Use a mock") }
        container.healthKitManager.register { fatalError("Use a mock") }
        container.permissionsManager.register { fatalError("Use a mock") }
        container.searchManager.register { fatalError("Use a mock") }
        container.storageManager.register { fatalError("Use a mock") }
        container.premiumManager.register { fatalError("Use a mock") }
        container.userManager.register { fatalError("Use a mock") }
        container.usersCache.register { fatalError("Use a mock") }
        container.workoutManager.register { fatalError("Use a mock") }
    }
}
