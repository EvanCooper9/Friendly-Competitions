import Combine
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseCrashlytics
import FirebaseFirestore
import FirebaseFunctions
import FirebaseFunctionsCombineSwift
import UIKit

// sourcery: AutoMockable
protocol UserManaging {
    var user: CurrentValueSubject<User, Never> { get }
    func deleteAccount() -> AnyPublisher<Void, Error>
    func update(with user: User) -> AnyPublisher<Void, Error>
}

final class UserManager: UserManaging {

    // MARK: - Public Properties

    var user: CurrentValueSubject<User, Never>

    // MARK: - Private Properties

    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.authenticationManager) private var authenticationManager
    @Injected(Container.functions) private var functions
    @Injected(Container.database) private var database

    private var cancellables = Cancellables()
    private var listenerBag = ListenerBag()

    init(user: User) {
        self.user = .init(user)
        if UIApplication.shared.applicationState == .active {
            listenForUser()
        }
    }

    func deleteAccount() -> AnyPublisher<Void, Error> {
        functions.httpsCallable("deleteAccount")
            .call()
            .mapToVoid()
            .flatMapLatest(withUnretained: self) { $0.authenticationManager.deleteAccount() }
            .handleEvents(withUnretained: self, receiveOutput: { try? $0.authenticationManager.signOut() })
            .eraseToAnyPublisher()
    }

    func update(with user: User) -> AnyPublisher<Void, Error> {
        guard user != self.user.value else { return .just(()) }
        return .fromAsync { [weak self] in
            try await self?.database.document("users/\(user.id)").updateDataEncodable(user)
        }
    }

    // MARK: - Private Methods

    private func listenForUser() {
        database.document("users/\(user.value.id)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                self.analyticsManager.set(userId: user.id)
                self.user.send(user)
            }
            .store(in: listenerBag)
    }
}
