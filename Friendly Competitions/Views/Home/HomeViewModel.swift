import Combine
import CombineExt
import ECKit
import Factory
import Foundation
import UIKit

final class HomeViewModel: ObservableObject {

    struct FriendRow: Equatable, Identifiable {
        var id: String { "\(user.id) - \(isInvitation)" }
        let user: User
        let activitySummary: ActivitySummary?
        let isInvitation: Bool
    }

    @Published var navigationDestinations = [NavigationDestination]()
    @Published var deepLinkedNavigationDestination: NavigationDestination?
    @Published private(set) var banners = [Banner]()
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friendRows = [FriendRow]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published private(set) var title = Bundle.main.name
    @Published var showAbout = false
    @Published private(set) var showDeveloper = false
    @Published private(set) var loadingDeepLink = false
    @Published private(set) var showPremiumBanner = false
    @Published var showNewCompetition = false
    @Published var showAddFriends = false
    @Published var showAnonymousAccountBlocker = false

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.activitySummaryManager) private var activitySummaryManager
    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.featureFlagManager) private var featureFlagManager
    @Injected(\.friendsManager) private var friendsManager
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.notificationsManager) private var notificationsManager
    @LazyInjected(\.premiumManager) private var premiumManager
    @Injected(\.scheduler) private var scheduler
    @Injected(\.userManager) private var userManager

    @UserDefault("dismissedPremiumBanner", defaultValue: false) private var dismissedPremiumBanner

    private let didHandleBannerTap = CurrentValueSubject<Void, Never>(())
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
            .flatMapLatest(withUnretained: self) { strongSelf, deepLink -> AnyPublisher<NavigationDestination?, Never> in
                guard let deepLink else { return .never() }
                return deepLink.navigationDestination
                    .isLoading { strongSelf.loadingDeepLink = $0 }
                    .eraseToAnyPublisher()
            }
            .receive(on: scheduler)
            .sink(withUnretained: self) { strongSelf, deepLinkedNavigationDestination in
                strongSelf.deepLinkedNavigationDestination = deepLinkedNavigationDestination
                strongSelf.showAddFriends = false
                strongSelf.showAnonymousAccountBlocker = false
                strongSelf.showNewCompetition = false
            }
            .store(in: &cancellables)

        competitionsManager.competitions
            .removeDuplicates()
            .receive(on: scheduler)
            .assign(to: &$competitions)

        competitionsManager.invitedCompetitions
            .removeDuplicates()
            .receive(on: scheduler)
            .assign(to: &$invitedCompetitions)

        Publishers
            .CombineLatest(friendsManager.friends, friendsManager.friendRequests)
            .map { $0.with(false) + $1.with(true) }
            .combineLatest(friendsManager.friendActivitySummaries.prepend([:]))
            .map { models, activitySummaries in
                models.map { friend, isInvitation in
                    FriendRow(
                        user: friend,
                        activitySummary: activitySummaries[friend.id],
                        isInvitation: isInvitation
                    )
                }
            }
            .removeDuplicates()
            .receive(on: scheduler)
            .assign(to: &$friendRows)

        handlePremiumBanner()
        bindBanners()

        userManager.userPublisher
            .filter { $0.isAnonymous != true }
            .map { $0.name.ifEmpty(Bundle.main.name) }
            .receive(on: scheduler)
            .assign(to: &$title)
    }

    // MARK: - Public Methods

    func dismissPremiumBannerTapped() {
        analyticsManager.log(event: .premiumBannerDismissed)
        dismissedPremiumBanner.toggle()
    }

    func newCompetitionTapped() {
        guard userManager.user.isAnonymous != true else {
            showAnonymousAccountBlocker = true
            return
        }

        showNewCompetition = true
    }

    func exploreCompetitionsTapped() {
        appState.set(rootTab: .explore)
    }

    func addFriendsTapped() {
        guard userManager.user.isAnonymous != true else {
            showAnonymousAccountBlocker = true
            return
        }

        showAddFriends = true
    }

    func exploreCompetitionsTapped() {
        
    }

    func aboutTapped() {
        showAbout = true
    }

    func tapped(banner: Banner) {
        banner.tapped()
            .sink(withUnretained: self) { strongSelf in
                strongSelf.banners.remove(banner)
                strongSelf.didHandleBannerTap.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func handlePremiumBanner() {
        guard featureFlagManager.value(forBool: .premiumEnabled) else { return }
        Publishers
            .CombineLatest3(
                $dismissedPremiumBanner,
                premiumManager.premium,
                competitionsManager.hasPremiumResults
            )
            .map { dismissedPremiumBanner, premium, hasPremiumResults in
                !dismissedPremiumBanner && premium == nil && hasPremiumResults
            }
            .receive(on: scheduler)
            .assign(to: &$showPremiumBanner)
    }

    private func bindBanners() {
        Publishers
            .CombineLatest(didHandleBannerTap, appState.didBecomeActive)
            .mapToVoid()
            .flatMapLatest(withUnretained: self) { strongSelf in
                let competitionBanners = strongSelf.$competitions
                    .flatMapLatest { competitions -> AnyPublisher<[Banner], Never> in
                        guard competitions.isNotEmpty else { return .just([]) }
                        return competitions
                            .map { $0.banners }
                            .combineLatest()
                            .map { $0.flattened() }
                            .eraseToAnyPublisher()
                    }

                let notificationBanner = strongSelf.notificationsManager
                    .permissionStatus()
                    .map { permissionStatus -> Banner? in
                        switch permissionStatus {
                        case .authorized, .done:
                            return nil
                        case .denied:
                            return .notificationPermissionsDenied
                        case .notDetermined:
                            return .notificationPermissionsMissing
                        }
                    }

                let resultsBanners = strongSelf.competitionsManager
                    .unseenResults()
                    .mapMany { competition, resultID in
                        Banner.newCompetitionResults(competition: competition, resultID: resultID)
                    }

                return Publishers
                    .CombineLatest3(competitionBanners, notificationBanner, resultsBanners)
                    .map { competitionBanners, notificationBanner, resultsBanners in
                        var allBanners = competitionBanners + resultsBanners
                        if let notificationBanner {
                            allBanners.append(notificationBanner)
                        }
                        return allBanners
                    }
                    .eraseToAnyPublisher()
            }
            .map { $0.uniqued(on: \.id) }
            .delay(for: .seconds(1), scheduler: scheduler)
            .assign(to: &$banners)
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
