import Combine
import ECKit
import Foundation

// sourcery: AutoMockable
protocol DeepLinkManaging {
    var deepLink: AnyPublisher<DeepLink?, Never> { get }
    func handle(url: URL)
    func push(deepLink: DeepLink)
}

final class DeepLinkManager: DeepLinkManaging {

    // MARK: - Public Properties

    let deepLink: AnyPublisher<DeepLink?, Never>

    // MARK: - Private Properties

    private let deepLinkSubject = CurrentValueSubject<DeepLink?, Never>(nil)

    // MARK: - Lifecycle

    init() {
        deepLink = deepLinkSubject.share(replay: 1).eraseToAnyPublisher()
    }

    // MARK: - Public Properties

    func handle(url: URL) {
        guard let deepLink = DeepLink(from: url) else { return }
        deepLinkSubject.send(deepLink)
    }

    func push(deepLink: DeepLink) {
        deepLinkSubject.send(deepLink)
    }
}
