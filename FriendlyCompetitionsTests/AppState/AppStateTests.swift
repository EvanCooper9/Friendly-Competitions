@testable import FriendlyCompetitions
import XCTest

final class AppStateTests: FCTestCase {
    func testThatDeepLinkIsEmitted() {
        let expectation = expectation(description: #function)

        let expectedDeepLinks: [DeepLink?] = [nil, .competition(id: "abc"), .user(id: "123")]
        
        let appState = AppState()
        appState.deepLink
            .collect(expectedDeepLinks.count)
            .expect(expectedDeepLinks, expectation: expectation)
            .store(in: &cancellables)

        expectedDeepLinks
            .compacted()
            .forEach { appState.push(deepLink: $0) }

        waitForExpectations(timeout: 1)
    }

    func testThatHudIsEmitted() {
        let expectation = expectation(description: #function)

        let expectedHuds: [HUD?] = [nil, .neutral(text: "neutral"), .success(text: "success")]

        let appState = AppState()
        appState.hud
            .collect(expectedHuds.count)
            .expect(expectedHuds, expectation: expectation)
            .store(in: &cancellables)

        expectedHuds
            .compacted()
            .forEach { appState.push(hud: $0) }

        waitForExpectations(timeout: 1)
    }

    func testThatDidBecomeActiveIsSent() {
        let expectation = expectation(description: #function)
        let expected = [true]

        let appState = AppState()
        appState.didBecomeActive
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        waitForExpectations(timeout: 1)
    }

    func testIsActive() {
        let expectation = expectation(description: #function)
        let expected = [true, false, true]

        let appState = AppState()
        appState.isActive
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        waitForExpectations(timeout: 1)
    }
}
