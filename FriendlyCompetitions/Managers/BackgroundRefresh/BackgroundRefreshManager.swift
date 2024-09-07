import Combine
import ECKit
import Factory
import UIKit

// sourcery: AutoMockable
protocol BackgroundRefreshManaging {
    var status: AnyPublisher<BackgroundRefreshStatus, Never> { get }
}

final class BackgroundRefreshManager: BackgroundRefreshManaging {

    // MARK: - Public Properties

    var status: AnyPublisher<BackgroundRefreshStatus, Never> { statusSubject.eraseToAnyPublisher() }

    // MARK: - Private Properties

    private let statusSubject: CurrentValueSubject<BackgroundRefreshStatus, Never>

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let status = BackgroundRefreshStatus(from: UIApplication.shared.backgroundRefreshStatus)
        statusSubject = .init(status)
        subscribeToStatusChange()
    }

    // MARK: - Private Methods

    private func subscribeToStatusChange() {
        UIApplication.backgroundRefreshStatusDidChangeNotification.publisher
            .prepend(())
            .sink(withUnretained: self) { strongSelf in
                let status = BackgroundRefreshStatus(from: UIApplication.shared.backgroundRefreshStatus)
                strongSelf.statusSubject.send(status)
            }
            .store(in: &cancellables)
    }
}
