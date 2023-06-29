import Combine

// sourcery: AutoMockable
protocol BannerManaging {
    var banner: AnyPublisher<Banner?, Never> { get }
    var bannerTapped: AnyPublisher<Banner, Never> { get }

    func push(banner: Banner)
    func pop()
    func tapped()
}

final class BannerManager: BannerManaging {

    // MARK: - Public Properties

    let banner: AnyPublisher<Banner?, Never>
    let bannerTapped: AnyPublisher<Banner, Never>

    // MARK: - Private Properties

    private let bannerSubject = CurrentValueSubject<Banner?, Never>(nil)
    private let bannerTappedSubject = PassthroughSubject<Banner, Never>()

    // MARK: - Lifecycle

    init() {
        banner = bannerSubject.eraseToAnyPublisher()
        bannerTapped = bannerTappedSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func push(banner: Banner) {
        bannerSubject.send(banner)
    }

    func pop() {
        bannerSubject.send(nil)
    }

    func tapped() {
        guard let banner = bannerSubject.value else { return }
        bannerTappedSubject.send(banner)
    }
}
