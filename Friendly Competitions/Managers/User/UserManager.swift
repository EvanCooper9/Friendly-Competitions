import Combine
import ECKit
import Factory
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import UIKit

// sourcery: AutoMockable
protocol UserManaging {
    var user: User { get }
    var userPublisher: AnyPublisher<User, Never> { get }
    func deleteAccount() -> AnyPublisher<Void, Error>
    func update(with user: User) -> AnyPublisher<Void, Error>
}

final class UserManager: UserManaging {

    // MARK: - Public Properties

    var user: User { userSubject.value }
    var userPublisher: AnyPublisher<User, Never>

    // MARK: - Private Properties

    @Injected(\.api) private var api
    @Injected(\.appState) private var appState
    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.authenticationManager) private var authenticationManager
    @Injected(\.database) private var database

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

    func deleteAccount() -> AnyPublisher<Void, Error> {
        api.call("deleteAccount")
            .flatMapLatest(withUnretained: self) { $0.authenticationManager.deleteAccount() }
            .handleEvents(withUnretained: self, receiveOutput: { try? $0.authenticationManager.signOut() })
            .eraseToAnyPublisher()
    }

    func update(with user: User) -> AnyPublisher<Void, Error> {
        database.document("users/\(user.id)")
            .set(value: user)
    }

    // MARK: - Private Methods

    private func listenForUser() {
        database.document("users/\(user.id)")
            .publisher(as: User.self)
            .removeDuplicates()
            .sink(withUnretained: self) { strongSelf, user in
                strongSelf.analyticsManager.set(userId: user.id)
                strongSelf.userSubject.send(user)
            }
            .store(in: &cancellables)
    }
}
