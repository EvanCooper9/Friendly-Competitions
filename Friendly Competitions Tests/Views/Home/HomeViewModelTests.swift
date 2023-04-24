import Combine
import CombineSchedulers
import ECKit
import Factory
import Foundation
import XCTest

@testable import Friendly_Competitions

final class HomeViewModelTests: FCTestCase {

    private var activitySummaryManager: ActivitySummaryManagingMock!
    private var analyticsManager: AnalyticsManagingMock!
    private var appState: AppStateProvidingMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var friendsManager: FriendsManagingMock!
    private var permissionsManager: PermissionsManagingMock!
    private var premiumManager: PremiumManagingMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()
        activitySummaryManager = .init()
        analyticsManager = .init()
        appState = .init()
        competitionsManager = .init()
        friendsManager = .init()
        permissionsManager = .init()
        premiumManager = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()
        cancellables = .init()

        activitySummaryManager.activitySummary = .never()
        appState.deepLink = .never()
        competitionsManager.competitions = .never()
        competitionsManager.invitedCompetitions = .never()
        competitionsManager.hasPremiumResults = .never()
        friendsManager.friends = .never()
        friendsManager.friendRequests = .never()
        friendsManager.friendActivitySummaries = .never()
        permissionsManager.requiresPermission = .never()
        premiumManager.premium = .never()
        userManager.userPublisher = .just(.evan)
        
        container.activitySummaryManager.register { self.activitySummaryManager }
        container.analyticsManager.register { self.analyticsManager }
        container.appState.register { self.appState }
        container.competitionsManager.register { self.competitionsManager }
        container.friendsManager.register { self.friendsManager }
        container.permissionsManager.register { self.permissionsManager }
        container.premiumManager.register { self.premiumManager }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.userManager.register { self.userManager }
    }

    func testThatActivitySummaryUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<ActivitySummary?, Never>(nil)
        activitySummaryManager.activitySummary = subject.eraseToAnyPublisher()

        let ac = ActivitySummary.mock

        let viewModel = HomeViewModel()
        viewModel.$activitySummary
            .expect(nil, nil, ac, nil, ac, expectation: expectation)
            .store(in: &cancellables)

        subject.send(ac)
        subject.send(nil)
        subject.send(ac)
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }

    func testThatCompetitionsUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<[Competition], Never>([])
        competitionsManager.competitions = subject.eraseToAnyPublisher()

        let comp1 = Competition.mock
        let comp2 = Competition.mockOld

        let viewModel = HomeViewModel()
        viewModel.$competitions
            .expect([], [], [comp1], [comp1, comp2], expectation: expectation)
            .store(in: &cancellables)

        subject.send([comp1])
        subject.send([comp1, comp2])
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }

    func testThatInvitedCompetitionsUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<[Competition], Never>([])
        competitionsManager.invitedCompetitions = subject.eraseToAnyPublisher()

        let comp1 = Competition.mock
        let comp2 = Competition.mockOld

        let viewModel = HomeViewModel()
        viewModel.$invitedCompetitions
            .expect([], [], [comp1], [comp1, comp2], expectation: expectation)
            .store(in: &cancellables)

        subject.send([comp1])
        subject.send([comp1, comp2])
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }

    func testThatFriendsUpdates() {
        let expectation = expectation(description: #function)

        let friends = CurrentValueSubject<[User], Never>([])
        friendsManager.friends = friends.eraseToAnyPublisher()
        let friendRequests = CurrentValueSubject<[User], Never>([])
        friendsManager.friendRequests = friendRequests.eraseToAnyPublisher()
        let friendActivitySummaries = CurrentValueSubject<[User.ID: ActivitySummary], Never>([:])
        friendsManager.friendActivitySummaries = friendActivitySummaries.eraseToAnyPublisher()

        let activitySummary = ActivitySummary.mock

        let evan = HomeViewModel.FriendRow(user: .evan, activitySummary: nil, isInvitation: false)
        let evanWithAC = HomeViewModel.FriendRow(user: .evan, activitySummary: activitySummary, isInvitation: false)
        let andrew = HomeViewModel.FriendRow(user: .andrew, activitySummary: nil, isInvitation: true)

        let viewModel = HomeViewModel()
        viewModel.$friendRows
            .expect([], [], [evan], [evanWithAC], [evanWithAC, andrew], expectation: expectation)
            .store(in: &cancellables)

        friends.send([.evan])
        friendActivitySummaries.send([User.evan.id: activitySummary])
        friendRequests.send([.andrew])
        scheduler.advance()

        waitForExpectations(timeout: 1)
    }

    func testThatRequiresPermissionUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<Bool, Never>(true)
        permissionsManager.requiresPermission = subject.eraseToAnyPublisher()

        let viewModel = HomeViewModel()
        viewModel.$requiresPermissions
            .expect(false, true, false, true, false, expectation: expectation)
            .store(in: &cancellables)

        subject.send(false)
        subject.send(true)
        subject.send(false)
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }

    func testThatTitleIsCorrect() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<User, Never>(.evan)
        userManager.userPublisher = subject.eraseToAnyPublisher()

        let viewModel = HomeViewModel()
        viewModel.$title
            .expect(Bundle.main.name, User.evan.name, Bundle.main.name, expectation: expectation)
            .store(in: &cancellables)

        let noName = User(id: "abc", email: "test@test.com", name: "")
        subject.send(noName)
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }
}
