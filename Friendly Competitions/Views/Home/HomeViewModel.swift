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

    @UserDefault("competitionsFiltered", defaultValue: false) var competitionsFiltered
    @UserDefault("dismissedPremiumBanner", defaultValue: false) private var dismissedPremiumBanner

    private let didRequestPermissions = CurrentValueSubject<Void, Never>(())
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
            .receive(on: scheduler)
            .assign(to: &$friendRows)

        handlePremiumBanner()
        bindPermissionBanners()

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

    func addFriendsTapped() {
        guard userManager.user.isAnonymous != true else {
            showAnonymousAccountBlocker = true
            return
        }

        showAddFriends = true
    }

    func aboutTapped() {
        showAbout = true
    }

    func tapped(banner: Banner) {
        switch banner {
        case .healthKitPermissionsMissing(let permissions):
            healthKitManager.request(permissions)
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .sink(withUnretained: self) { strongSelf in
                    strongSelf.banners.remove(banner)
                    strongSelf.didRequestPermissions.send()
                }
                .store(in: &cancellables)
        case .healthKitDataMissing:
            UIApplication.shared.open(.health)
        case .notificationPermissionsMissing:
            notificationsManager.requestPermissions()
                .mapToVoid()
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .sink(withUnretained: self) { strongSelf in
                    strongSelf.banners.remove(banner)
                    strongSelf.didRequestPermissions.send()
                }
                .store(in: &cancellables)
        case .notificationPermissionsDenied:
            UIApplication.shared.open(.notificationSettings)
        }
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

    private func bindPermissionBanners() {
        Publishers
            .CombineLatest(didRequestPermissions, $competitions)
            .flatMapLatest { _, competitions in
                competitions
                    .map { $0.banners }
                    .combineLatest()
                    .map { $0.flattened() }
            }
            .map { $0.uniqued(on: \.id) }
            .assign(to: &$banners)
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
