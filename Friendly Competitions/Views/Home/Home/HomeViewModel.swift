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
    
    @Published private(set) var showPremiumBanner = false
    @Published var showPaywall = false
    
    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    @Injected(Container.activitySummaryManager) private var activitySummaryManager
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.permissionsManager) private var permissionsManager
    @Injected(Container.storeKitManager) private var storeKitManager
    @Injected(Container.userManager) private var userManager
    
    @UserDefault("competitionsFiltered") var competitionsFiltered = false
    @UserDefault("dismissedPremiumBanner") private var dismissedPremiumBanner = false
    
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
                        .unwrap()
                        .map { [.user($0)] }
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                case .competition(let id):
                    return strongSelf.competitionsManager.search(byID: id)
                        .unwrap()
                        .map { [.competition($0)] }
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                case .competitionResults(let id):
                    return strongSelf.competitionsManager.search(byID: id)
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
            .CombineLatest($dismissedPremiumBanner, storeKitManager.hasPremium)
            .map { !$1 && !$1 }
            .receive(on: RunLoop.main)
            .assign(to: &$showPremiumBanner)
        
        userManager.userPublisher
            .map { $0.name.ifEmpty(Bundle.main.name) }
            .assign(to: &$title)
    }
    
    func purchaseTapped() {
        showPaywall.toggle()
    }
    
    func dismissPremiumBannerTapped() {
        dismissedPremiumBanner.toggle()
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
