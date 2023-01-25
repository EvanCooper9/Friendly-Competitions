import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class HomeViewModel: ObservableObject {
    
    struct FriendRow: Equatable, Identifiable {
        var id: String { "\(user.id) - \(isInvitation)" }
        let user: User
        let activitySummary: ActivitySummary?
        let isInvitation: Bool
    }
    
    @Published var navigationDestinations = [NavigationDestination]()
    
    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friendRows = [FriendRow]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published var requiresPermissions = false
    @Published private(set) var title = Bundle.main.name
    @Published private(set) var showDeveloper = false
    @Published private(set) var loadingDeepLink = false
    @Published private(set) var showPremiumBanner = false
    @Published var showPaywall = false
    
    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    @Injected(Container.activitySummaryManager) private var activitySummaryManager
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.permissionsManager) private var permissionsManager
    @Injected(Container.premiumManager) private var premiumManager
    @Injected(Container.userManager) private var userManager
    
    @UserDefault("competitionsFiltered", defaultValue: false) var competitionsFiltered
    @UserDefault("dismissedPremiumBanner", defaultValue: false) private var dismissedPremiumBanner
    
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle

    init() {

        #if DEBUG
        showDeveloper = true
        #else
        userManager.userPublisher
            .map { ["evan.cooper@rogers.com", "evancmcooper@gmail.com"].contains($0.email) }
            .assign(to: &$showDeveloper)
        #endif
        
        appState.deepLink
            .flatMapLatest(withUnretained: self) { strongSelf, deepLink -> AnyPublisher<[NavigationDestination], Never> in
                switch deepLink {
                case .user(let id):
                    return strongSelf.friendsManager.user(withId: id)
                        .isLoading { strongSelf.loadingDeepLink = $0 }
                        .unwrap()
                        .map { [.user($0)] }
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                case .competition(let id):
                    return strongSelf.competitionsManager.search(byID: id)
                        .isLoading { strongSelf.loadingDeepLink = $0 }
                        .unwrap()
                        .map { [.competition($0)] }
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                case .competitionResults(let id):
                    return strongSelf.competitionsManager.search(byID: id)
                        .isLoading { strongSelf.loadingDeepLink = $0 }
                        .unwrap()
                        .map { [.competition($0), .competitionResults($0)] }
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                case .none:
                    return .just([])
                }
            }
            .assign(to: &$navigationDestinations)

        activitySummaryManager.activitySummary.assign(to: &$activitySummary)
        competitionsManager.competitions.assign(to: &$competitions)
        competitionsManager.invitedCompetitions.assign(to: &$invitedCompetitions)
        
        Publishers
            .CombineLatest4($competitions, $invitedCompetitions, $friendRows, appState.deepLink)
            .map { [weak self] competitions, invitedCompetitions, friendRows, deepLink -> [NavigationDestination] in
                guard let strongSelf = self else { return [] }
                let homeScreenCompetitionIDs = Set(competitions.map(\.id) + invitedCompetitions.map(\.id))
                let homeScreenFriendIDs = Set(friendRows.map(\.user.id))
                return strongSelf.navigationDestinations.filter { navigationDestination in
                    // accont for deep link to ensure that if comp/friend lists updates, then the deep link isn't dismissed
                    switch (navigationDestination, deepLink) {
                    case (.competition(let competition), .competition(id: let deepLinkedCompeititonID)):
                        return homeScreenCompetitionIDs.contains(competition.id) || deepLinkedCompeititonID == competition.id
                    case (.competition(let competition), nil):
                        return homeScreenCompetitionIDs.contains(competition.id)
                    case (.competitionResults(let competition), .competitionResults(id: let deepLinkedCompeititonID)):
                        return homeScreenCompetitionIDs.contains(competition.id) || deepLinkedCompeititonID == competition.id
                    case (.competitionResults(let competition), nil):
                        return homeScreenCompetitionIDs.contains(competition.id)
                    case (.user(let user), .user(id: let deepLinkedUserID)):
                        return homeScreenFriendIDs.contains(user.id) || deepLinkedUserID == user.id
                    case (.user(let user), nil):
                        return homeScreenFriendIDs.contains(user.id)
                    default:
                        return true
                    }
                }
            }
            .assign(to: &$navigationDestinations)
        
        Publishers
            .CombineLatest(friendsManager.friends, friendsManager.friendRequests)
            .map { $0.with(false) + $1.with(true) }
            .combineLatest(friendsManager.friendActivitySummaries)
            .map { models, activitySummaries in
                models.map { friend, isInvitation in
                    FriendRow(
                        user: friend,
                        activitySummary: activitySummaries[friend.id],
                        isInvitation: isInvitation
                    )
                }
            }
            .assign(to: &$friendRows)

        permissionsManager
            .requiresPermission
            .assign(to: &$requiresPermissions)
        
        Publishers
            .CombineLatest(
                $dismissedPremiumBanner,
                premiumManager.premium.map { $0 != nil }
            )
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, result in
                let (_, premium) = result
                guard premium else { return }
                // show banner again when premium expires
                strongSelf.dismissedPremiumBanner = false
            })
            .map { !$0 && !$1 }
            .receive(on: RunLoop.main)
            .assign(to: &$showPremiumBanner)
        
        userManager.userPublisher
            .map { $0.name.ifEmpty(Bundle.main.name) }
            .assign(to: &$title)
    }
    
    func dismissPremiumBannerTapped() {
        analyticsManager.log(event: .premiumBannerDismissed)
        dismissedPremiumBanner.toggle()
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
