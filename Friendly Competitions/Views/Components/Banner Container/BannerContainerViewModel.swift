import Combine
import CombineExt
import ECKit
import Factory
import SwiftUI

final class BannerContainerViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var banner: Banner?

    // MARK: - Private Properties

    @Injected(\.bannerManager) private var bannerManager

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        bannerManager.banner
            .receive(on: RunLoop.main)
            .assign(to: &$banner)
    }

    // MARK: Public Methods

    func tapped() {
        bannerManager.tapped()
    }
}
