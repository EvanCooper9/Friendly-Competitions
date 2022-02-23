import Resolver
import XCTest

@testable import Friendly_Competitions

final class ResolverTests: XCTestCase {
    func testThatMocksAreNotUsed() {
        Resolver.registerAllServices()
        XCTAssertTrue(Resolver.resolve(AnyActivitySummaryManager.self) is ActivitySummaryManager)
        XCTAssertTrue(Resolver.resolve(AnyAuthenticationManager.self) is AuthenticationManager)
        XCTAssertTrue(Resolver.resolve(AnyCompetitionsManager.self) is CompetitionsManager)
        XCTAssertTrue(Resolver.resolve(AnyFriendsManager.self) is FriendsManager)
        XCTAssertTrue(Resolver.resolve(AnyHealthKitManager.self) is HealthKitManager)
        XCTAssertTrue(Resolver.resolve(NotificationManaging.self) is NotificationManager)
        XCTAssertTrue(Resolver.resolve(AnyPermissionsManager.self) is PermissionsManager)
        XCTAssertTrue(Resolver.resolve(AnyStorageManager.self) is StorageManager)
    }
}
