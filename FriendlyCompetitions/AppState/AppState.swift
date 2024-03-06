import Combine
import ECKit
import UIKit

// sourcery: AutoMockable
protocol AppStateProviding {
    var rootTab: AnyPublisher<RootTab, Never> { get }
    var deepLink: AnyPublisher<DeepLink?, Never> { get }
    var hud: AnyPublisher<HUD?, Never> { get }
    var didBecomeActive: AnyPublisher<Bool, Never> { get }
    var isActive: AnyPublisher<Bool, Never> { get }

    func push(hud: HUD)
    func push(deepLink: DeepLink)
    func set(rootTab: RootTab)
}

final class AppState: AppStateProviding {

    // MARK: - Public Properties

    let rootTab: AnyPublisher<RootTab, Never>
    let deepLink: AnyPublisher<DeepLink?, Never>
    let hud: AnyPublisher<HUD?, Never>
    let didBecomeActive: AnyPublisher<Bool, Never>
    let isActive: AnyPublisher<Bool, Never>

    // MARK: - Private Properties

    private let rootTabSubject = PassthroughSubject<RootTab, Never>()
    private let deepLinkSubject = CurrentValueSubject<DeepLink?, Never>(nil)
    private let hudSubject = CurrentValueSubject<HUD?, Never>(nil)
    private var cancellabes = Cancellables()

    // MARK: - Lifecycle

    init() {
        rootTab = rootTabSubject.share().eraseToAnyPublisher()
        deepLink = deepLinkSubject.share(replay: 1).eraseToAnyPublisher()
        hud = hudSubject.share(replay: 1).eraseToAnyPublisher()

        didBecomeActive = UIApplication.didBecomeActiveNotification.publisher
            .mapToValue(true)
            .eraseToAnyPublisher()

        isActive = Publishers
            .Merge(
                UIApplication.didBecomeActiveNotification.publisher.mapToValue(true)
                    .print("> DEBUGGING didBecomeActiveNotification"),
                UIApplication.didEnterBackgroundNotification.publisher.mapToValue(false)
                    .print("> DEBUGGING didEnterBackgroundNotification")
            )
            .share(replay: 1)
            .print("> DEBUGGING isActive")
            .eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func push(hud: HUD) {
        hudSubject.send(hud)
    }

    func push(deepLink: DeepLink) {
        deepLinkSubject.send(deepLink)
    }

    func set(rootTab: RootTab) {
        rootTabSubject.send(rootTab)
    }
}
