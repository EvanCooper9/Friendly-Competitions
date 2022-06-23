import Resolver
import XCTest

@testable import Friendly_Competitions

final class ResolverTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        Resolver.reset()
    }

    func testThatMocksAreNotUsed() {
        Resolver.registerAllServices()
        Resolver.register(UserManaging.self) { UserManager(user: .evan) }
        XCTAssertTrue(Resolver.resolve(ActivitySummaryManaging.self) is ActivitySummaryManager)
        XCTAssertTrue(Resolver.resolve(AnalyticsManaging.self) is AnalyticsManager)
        XCTAssertTrue(Resolver.resolve(AuthenticationManaging.self) is AuthenticationManager)
        XCTAssertTrue(Resolver.resolve(CompetitionsManaging.self) is CompetitionsManager)
        XCTAssertTrue(Resolver.resolve(FriendsManaging.self) is FriendsManager)
        XCTAssertTrue(Resolver.resolve(HealthKitManaging.self) is HealthKitManager)
        XCTAssertTrue(Resolver.resolve(NotificationManaging.self) is NotificationManager)
        XCTAssertTrue(Resolver.resolve(PermissionsManaging.self) is PermissionsManager)
        XCTAssertTrue(Resolver.resolve(StorageManaging.self) is StorageManager)
    }
}
