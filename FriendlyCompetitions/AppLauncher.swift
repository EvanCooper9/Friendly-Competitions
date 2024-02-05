import Foundation

@main
struct AppLauncher {
    static func main() throws {
        if NSClassFromString("XCTestCase") == nil {
            FriendlyCompetitions.main()
        } else {
            FriendlyCompetitionsTests.main()
        }
    }
}
