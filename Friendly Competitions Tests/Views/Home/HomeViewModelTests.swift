import Combine
import CombineSchedulers
import ECKit
import Factory
import Foundation
import XCTest

@testable import Friendly_Competitions

final class HomeViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()

        activitySummaryManager.activitySummary = .never()
        activitySummaryManager.activitySummariesInReturnValue = .never()
        appState.deepLink = .never()
        appState.didBecomeActive = .never()
        competitionsManager.competitions = .never()
        competitionsManager.invitedCompetitions = .never()
        competitionsManager.hasPremiumResults = .never()
        featureFlagManager.valueForBoolReturnValue = false
        friendsManager.friends = .never()
        friendsManager.friendRequests = .never()
        friendsManager.friendActivitySummaries = .never()
        healthKitManager.shouldRequestReturnValue = .never()
        notificationsManager.permissionStatusReturnValue = .never()
        premiumManager.premium = .never()
        userManager.userPublisher = .never()
        userManager.user = .evan
    }

    func testThatDeepLinkSetsNavigationDestination() {
        let deepLinkSubject = PassthroughSubject<DeepLink?, Never>()
        appState.deepLink = deepLinkSubject.eraseToAnyPublisher()

        let competition = Competition.mock
        competitionsManager.searchByIDReturnValue = .just(competition)
        let competitionResult = CompetitionResult(id: "abc", start: .distantPast, end: .now, participants: [])

        let competitionDocument = DocumentMock<Competition>()
        competitionDocument.getClosure = { _, _ in .just(competition) }
        let competitionResultDocument = DocumentMock<CompetitionResult>()
        competitionResultDocument.getClosure = { _, _ in .just(competitionResult) }
        database.documentClosure = { path -> Document in
            path.contains("result") ? competitionResultDocument : competitionDocument
        }

        let user = User.evan
        friendsManager.userWithIdReturnValue = .just(user)

        let viewModel = HomeViewModel()

        deepLinkSubject.send(.competition(id: competition.id))
        scheduler.advance()
        XCTAssertEqual(viewModel.deepLinkedNavigationDestination, .competition(competition, nil))

        deepLinkSubject.send(.competitionResult(id: competition.id, resultID: nil))
        scheduler.advance()
        XCTAssertEqual(viewModel.deepLinkedNavigationDestination, .competition(competition, nil))

        deepLinkSubject.send(.competitionResult(id: competition.id, resultID: "abc"))
        scheduler.advance()
        XCTAssertEqual(viewModel.deepLinkedNavigationDestination, .competition(competition, competitionResult))

        deepLinkSubject.send(.user(id: user.id))
        scheduler.advance()
        XCTAssertEqual(viewModel.deepLinkedNavigationDestination, .user(user))
    }

    func testThatCompetitionsUpdates() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<[Competition], Never>([])
        competitionsManager.competitions = subject.eraseToAnyPublisher()

        let comp1 = Competition.mock
        let comp2 = Competition.mockOld

        let viewModel = HomeViewModel()
        viewModel.$competitions
            .print("competitions")
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

    func testThatTitleIsCorrect() {
        let expectation = expectation(description: #function)

        let subject = CurrentValueSubject<User, Never>(.evan)
        userManager.userPublisher = subject.eraseToAnyPublisher()

        let viewModel = HomeViewModel()
        viewModel.$title
            .expect(Bundle.main.name, User.evan.name, Bundle.main.name, expectation: expectation)
            .store(in: &cancellables)

        let noName = User(id: "abc", name: "", email: "test@test.com")
        subject.send(noName)
        scheduler.advance()
        waitForExpectations(timeout: 1)
    }

    func testThatExploreSetsRootTab() {
        let viewModel = HomeViewModel()
        viewModel.exploreCompetitionsTapped()
        XCTAssertTrue(appState.setRootTabCalled)
        XCTAssertEqual(appState.setRootTabReceivedInvocations, [.explore])
    }
}
