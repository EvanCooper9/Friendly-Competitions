import Combine
import ECKit
import UIKit

// sourcery: AutoMockable
protocol AppStateProviding {
    var deepLink: AnyPublisher<DeepLink?, Never> { get }
    var hud: AnyPublisher<HUD?, Never> { get }
    var didBecomeActive: AnyPublisher<Bool, Never> { get }
    
    func push(hud: HUD)
    func push(deepLink: DeepLink)
}

final class AppState: AppStateProviding {
    
    // MARK: - Public Properties
    
    let deepLink: AnyPublisher<DeepLink?, Never>
    let hud: AnyPublisher<HUD?, Never>
    let didBecomeActive: AnyPublisher<Bool, Never>
    
    // MARK: - Private Properties
    
    private let deepLinkSubject = CurrentValueSubject<DeepLink?, Never>(nil)
    private let hudSubject = CurrentValueSubject<HUD?, Never>(nil)
    private let didBecomeActiveSubject = CurrentValueSubject<Bool, Never>(false)
    private var cancellabes = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        deepLink = deepLinkSubject.share(replay: 1).eraseToAnyPublisher()
        hud = hudSubject.share(replay: 1).eraseToAnyPublisher()
        didBecomeActive = didBecomeActiveSubject.share(replay: 1).eraseToAnyPublisher()
        
        UIApplication.didBecomeActiveNotification.publisher
            .first()
            .mapToValue(true)
            .sink(withUnretained: self) { $0.didBecomeActiveSubject.send($1) }
            .store(in: &cancellabes)
    }
    
    // MARK: - Public Methods
    
    func push(hud: HUD) {
        hudSubject.send(hud)
    }
    
    func push(deepLink: DeepLink) {
        deepLinkSubject.send(deepLink)
    }
}
