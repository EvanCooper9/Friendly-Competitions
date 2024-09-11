import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Foundation

final class NotificationsViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var banners = [Banner]()
    @Published private(set) var loading = false
    @Published private(set) var dismiss = false

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
            .isLoading { [weak self] in self?.loading = $0 }
            .sink { [weak self] in self?.dismiss = true }
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
