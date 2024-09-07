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
    @Published var showAbout = false
    @Published private(set) var showDeveloper = false
    @Published private(set) var loadingDeepLink = false
    @Published var showNewCompetition = false
    @Published var showAddFriends = false
    @Published var showAnonymousAccountBlocker = false
    @Published private(set) var googleAdUnit: GoogleAdUnit?

    // MARK: - Private Properties

    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.activitySummaryManager) private var activitySummaryManager: ActivitySummaryManaging
    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
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
            googleAdUnit = .native(unit: featureFlagManager.value(forString: .googleAdsExploreScreenAdUnit))
        }

        bindBanners()
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

    func requestPermissionsForSteps() {
        healthKitManager.request([.stepCount])
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func bindBanners() {
        Publishers
            .CombineLatest(didHandleBannerTap, appState.didBecomeActive)
            .mapToVoid()
            .prepend(())
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
                    .unseenResults
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
            .map { banners in
                banners
                    .uniqued(on: \.id)
                    .sorted()
            }
            .filterMany { $0.showsOnHomeScreen }
            .delay(for: .seconds(1), scheduler: scheduler)
            .assign(to: &$banners)
    }
}

private extension Array {
    func with<T>(_ value: T) -> [(Element, T)] {
        map { ($0, value) }
    }
}
