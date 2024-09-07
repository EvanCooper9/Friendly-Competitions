import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Foundation

final class NotificationsViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var banners = [Banner]()

    // MARK: - Private Properties

    @Injected(\.bannerManager) private var bannerManager: BannerManaging

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        bannerManager.banners.assign(to: &$banners)
    }

    // MARK: - Public Methods

    func tapped(_ banner: Banner) {
        bannerManager.tapped(banner)
            .sink()
            .store(in: &cancellables)
    }

    func dismissed(_ banner: Banner) {
        bannerManager.dismissed(banner)
            .sink()
            .store(in: &cancellables)
    }

    func reset() {
        bannerManager.resetDismissed()
    }
}
