import Combine
import ECKit
import Factory
import Foundation
import XCTest

@testable import Friendly_Competitions

final class DashboardViewModelTests: XCTestCase {

    private var activitySummaryManager: ActivitySummaryManagingMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var friendsManager: FriendsManagingMock!
    private var permissionsManager: PermissionsManagingMock!
    private var userManager: UserManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        activitySummaryManager = .init()
        competitionsManager = .init()
        friendsManager = .init()
        permissionsManager = .init()
        userManager = .init()
        cancellables = .init()

        activitySummaryManager.activitySummary = .never()
        competitionsManager.competitions = .never()
        competitionsManager.invitedCompetitions = .never()
        friendsManager.friends = .never()
        friendsManager.friendRequests = .never()
        friendsManager.friendActivitySummaries = .never()
        permissionsManager.requiresPermission = .never()
        userManager.user = .init(.evan)
        
        Container.activitySummaryManager.register { self.activitySummaryManager }
        Container.competitionsManager.register { self.competitionsManager }
        Container.friendsManager.register { self.friendsManager }
        Container.permissionsManager.register { self.permissionsManager }
        Container.userManager.register { self.userManager }

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        activitySummaryManager = nil
        competitionsManager = nil
        friendsManager = nil
        permissionsManager = nil
        userManager = nil
        cancellables = nil
    }

    func testThatActivitySummaryUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<ActivitySummary?, Never>(nil)
        activitySummaryManager.activitySummary = subject.eraseToAnyPublisher()

        let ac = ActivitySummary.mock

        let viewModel = DashboardViewModel()
        viewModel.$activitySummary
            .expect(nil, ac, nil, ac, expectation: expectation)
            .store(in: &cancellables)

        subject.send(ac)
        subject.send(nil)
        subject.send(ac)
        waitForExpectations(timeout: 1)
    }

    func testThatCompetitionsUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<[Competition], Never>([])
        competitionsManager.competitions = subject.eraseToAnyPublisher()

        let comp1 = Competition.mock
        let comp2 = Competition.mockOld

        let viewModel = DashboardViewModel()
        viewModel.$competitions
            .expect([], [comp1], [comp1, comp2], expectation: expectation)
            .store(in: &cancellables)

        subject.send([comp1])
        subject.send([comp1, comp2])
        waitForExpectations(timeout: 1)
    }

    func testThatInvitedCompetitionsUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<[Competition], Never>([])
        competitionsManager.invitedCompetitions = subject.eraseToAnyPublisher()

        let comp1 = Competition.mock
        let comp2 = Competition.mockOld

        let viewModel = DashboardViewModel()
        viewModel.$invitedCompetitions
            .expect([], [comp1], [comp1, comp2], expectation: expectation)
            .store(in: &cancellables)

        subject.send([comp1])
        subject.send([comp1, comp2])
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

        let evan = DashboardViewModel.FriendRow(user: .evan, activitySummary: nil, isInvitation: false)
        let evanWithAC = DashboardViewModel.FriendRow(user: .evan, activitySummary: activitySummary, isInvitation: false)
        let andrew = DashboardViewModel.FriendRow(user: .andrew, activitySummary: nil, isInvitation: true)

        let viewModel = DashboardViewModel()
        viewModel.$friends
            .expect([], [evan], [evanWithAC], [evanWithAC, andrew], expectation: expectation)
            .store(in: &cancellables)

        friends.send([.evan])
        friendActivitySummaries.send([User.evan.id: activitySummary])
        friendRequests.send([.andrew])

        waitForExpectations(timeout: 1)
    }

    func testThatRequiresPermissionUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<Bool, Never>(true)
        permissionsManager.requiresPermission = subject.eraseToAnyPublisher()

        let viewModel = DashboardViewModel()
        viewModel.$requiresPermissions
            .expect(true, false, true, false, expectation: expectation)
            .store(in: &cancellables)

        subject.send(false)
        subject.send(true)
        subject.send(false)
        waitForExpectations(timeout: 1)
    }

    func testThatTitleIsCorrect() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<User, Never>(.evan)
        userManager.user = subject

        let viewModel = DashboardViewModel()
        viewModel.$title
            .expect(User.evan.name, Bundle.main.name, expectation: expectation)
            .store(in: &cancellables)

        let noName = User(id: "abc", email: "test@test.com", name: "")
        subject.send(noName)

        waitForExpectations(timeout: 1)
    }
}
