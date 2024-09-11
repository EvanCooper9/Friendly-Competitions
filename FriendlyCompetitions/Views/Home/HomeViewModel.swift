import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import FCKit
import Foundation
import UIKit

final class HomeViewModel: ObservableObject {

    struct FriendRow: Equatable, Identifiable {
        var id: String { "\(user.id) - \(isInvitation)" }
        let user: User
        let activitySummary: ActivitySummary?
        let isInvitation: Bool
    }

    enum Steps {
        case value(Int)
        case requiresPermission
    }

    @Published var navigationDestinations = [NavigationDestination]()
    @Published var deepLinkedNavigationDestination: NavigationDestination?
    @Published private(set) var banners = [Banner]()
    @Published private(set) var steps = Steps.requiresPermission
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friendRows = [FriendRow]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published private(set) var hasNotifications = false

    @Published private(set) var showDeveloper = false
    @Published private(set) var loadingDeepLink = false
    @Published var showNewCompetition = false
    @Published var showAddFriends = false
    @Published var showAnonymousAccountBlocker = false
    @Published var showNotifications = false
    @Published private(set) var googleAdUnit: GoogleAdUnit?

    // MARK: - Private Properties

    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.activitySummaryManager) private var activitySummaryManager: ActivitySummaryManaging
    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.backgroundRefreshManager) private var backgroundRefreshManager: BackgroundRefreshManaging
    @Injected(\.bannerManager) private var bannerManager: BannerManaging
    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.friendsManager) private var friendsManager: FriendsManaging
    @Injected(\.healthKitManager) private var healthKitManager: HealthKitManaging
    @Injected(\.notificationsManager) private var notificationsManager: NotificationsManaging
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.stepCountManager) private var stepCountManager: StepCountManaging
    @Injected(\.userManager) private var userManager: UserManaging

    private let didHandleBannerTap = CurrentValueSubject<Void, Never>(())
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {

        #if targetEnvironment(simulator)
        showDeveloper = true
        #elseif DEBUG
        showDeveloper = true
        #else
        userManager.userPublisher
            .map { $0.tags.contains(.admin) }
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

        Publishers
            .CombineLatest(healthKitManager.permissionsChanged, appState.isActive.filter { $0 })
            .mapToVoid()
            .prepend(())
            .flatMapLatest { [healthKitManager] in
                healthKitManager
                    .shouldRequest([.stepCount])
                    .catchErrorJustReturn(false)
            }
            .flatMapLatest { [stepCountManager] shouldRequest -> AnyPublisher<Steps, Never> in
                if shouldRequest {
                    return .just(.requiresPermission)
                } else {
                    let dateInterval = DateInterval(start: Calendar.current.startOfDay(for: .now), end: .now)
                    return stepCountManager.stepCounts(in: dateInterval)
                        .mapMany(\.count)
                        .map { $0.reduce(0, +) }
                        .map { Steps.value($0) }
                        .catchErrorJustReturn(Steps.value(0))
                        .eraseToAnyPublisher()
                }
            }
            .receive(on: scheduler)
            .assign(to: &$steps)

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

        if featureFlagManager.value(forBool: .adsEnabled) {
            googleAdUnit = .native(unit: featureFlagManager.value(forString: .googleAdsHomeScreenAdUnit))
        }

        bannerManager.banners
            .map(\.isNotEmpty)
            .assign(to: &$hasNotifications)

        bannerManager.banners
            .filterMany(\.showsOnHomeScreen)
            .assign(to: &$banners)
    }

    // MARK: - Public Methods

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

    func tapped(_ banner: Banner) {
        bannerManager.tapped(banner)
            .sink(withUnretained: self) { strongSelf in
                strongSelf.banners.remove(banner)
                strongSelf.didHandleBannerTap.send()
            }
            .store(in: &cancellables)
    }

    func dismissed(_ banner: Banner) {
        bannerManager.dismissed(banner)
            .sink()
            .store(in: &cancellables)
    }

    func requestPermissionsForSteps() {
        healthKitManager.request([.stepCount])
            .sink()
            .store(in: &cancellables)
    }

    func notificationsTapped() {
        showNotifications = true
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
