import Combine
import ECKit
import Factory
import FCKit
import Firebase
import UIKit

// sourcery: AutoMockable
protocol UserManaging {
    var user: User { get }
    var userPublisher: AnyPublisher<User, Never> { get }
    func update(with user: User) -> AnyPublisher<Void, Error>
}

final class UserManager: UserManaging {

    // MARK: - Public Properties

    var user: User { userSubject.value }
    var userPublisher: AnyPublisher<User, Never>

    // MARK: - Private Properties

    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @Injected(\.database) private var database: Database

    private let userSubject: CurrentValueSubject<User, Never>

    private var cancellables = Cancellables()

    init(user: User) {
        userSubject = .init(user)
        userPublisher = userSubject
            .removeDuplicates()
            .share(replay: 1)
            .eraseToAnyPublisher()

        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .sink(withUnretained: self) { $0.listenForUser() }
            .store(in: &cancellables)
    }

    func update(with user: User) -> AnyPublisher<Void, Error> {
        database.document("users/\(user.id)")
            .set(value: user)
    }

    // MARK: - Private Methods

    private func listenForUser() {
        database.document("users/\(user.id)")
            .publisher(as: User.self)
            .sink(withUnretained: self) { strongSelf, user in
                strongSelf.analyticsManager.set(userId: user.id)
                strongSelf.userSubject.send(user)
            }
            .store(in: &cancellables)
    }
}
