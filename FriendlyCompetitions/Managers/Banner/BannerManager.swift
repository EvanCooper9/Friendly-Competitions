import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol BannerManaging {
    var banners: AnyPublisher<[Banner], Never> { get }
    func tapped(_ banner: Banner) -> AnyPublisher<Void, Never>
    func dismissed(_ banner: Banner) -> AnyPublisher<Void, Never>
    func resetDismissed()
}

final class BannerManager: BannerManaging {

    // MARK: - Public Properties

    let banners: AnyPublisher<[Banner], Never>

    // MARK: - Private Properties

    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.backgroundRefreshManager) private var backgroundRefreshManager: BackgroundRefreshManaging
    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.notificationsManager) private var notificationsManager: NotificationsManaging
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>

    @UserDefault("dissmised-banners", defaultValue: Set<Banner.ID>()) private var dismissedBanners

    private let bannersSubject = CurrentValueSubject<[Banner], Never>([])
    private let didHandleBannerTap = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        banners = bannersSubject.eraseToAnyPublisher()
        bindBanners()
    }

    // MARK: - Public Methods

    func tapped(_ banner: Banner) -> AnyPublisher<Void, Never> {
        banner
            .tapped()
            .handleEvents(receiveOutput: { [didHandleBannerTap] in
                didHandleBannerTap.send()
            })
            .eraseToAnyPublisher()
    }

    func dismissed(_ banner: Banner) -> AnyPublisher<Void, Never> {
        dismissedBanners.insert(banner.id)
        didHandleBannerTap.send()
        return .just(())
    }

    func resetDismissed() {
        dismissedBanners.removeAll()
        didHandleBannerTap.send()
    }

    // MARK: - Private Methods

    private func bindBanners() {
        Publishers
            .CombineLatest(didHandleBannerTap, appState.didBecomeActive)
            .mapToVoid()
            .prepend(())
            .flatMapLatest(withUnretained: self) { [backgroundRefreshManager, competitionsManager, notificationsManager] strongSelf in
                let competitionBanners = competitionsManager.competitions
                    .flatMapLatest { competitions -> AnyPublisher<[Banner], Never> in
                        guard competitions.isNotEmpty else { return .just([]) }
                        return competitions
                            .map(\.banners)
                            .combineLatest()
                            .map { $0.flattened() }
                            .eraseToAnyPublisher()
                    }
                    .prepend([])

                let notificationBanner = notificationsManager.permissionStatus()
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
                    .prepend(nil)

                let resultsBanners = competitionsManager.unseenResults
                    .mapMany { competition, resultID in
                        Banner.newCompetitionResults(competition: competition, resultID: resultID)
                    }
                    .prepend([])

                let backgroundRefreshBanner = backgroundRefreshManager.status
                    .map { status -> Banner? in
                        switch status {
                        case .available, .restricted, .unknown:
                            return nil
                        case .denied:
                            return .backgroundRefreshDenied
                        }
                    }
                    .prepend(nil)

                return Publishers
                    .CombineLatest4(competitionBanners, notificationBanner, resultsBanners, backgroundRefreshBanner)
                    .map { competitionBanners, notificationBanner, resultsBanners, backgroundRefreshBanner in
                        var allBanners = competitionBanners + resultsBanners
                        if let notificationBanner {
                            allBanners.append(notificationBanner)
                        }
                        if let backgroundRefreshBanner {
                            allBanners.append(backgroundRefreshBanner)
                        }
                        return allBanners
                    }
                    .filterMany { banner in
                        !strongSelf.dismissedBanners.contains(banner.id)
                    }
                    .eraseToAnyPublisher()
            }
            .map { banners in
                banners
                    .uniqued(on: \.id)
                    .sorted()
            }
            .receive(on: scheduler)
            .sink(receiveValue: { [bannersSubject] banners in
                bannersSubject.send(banners)
            })
            .store(in: &cancellables)
    }

}
