import Combine
import ECKit
import ECKit_Firebase
import Firebase
import FirebaseCrashlytics
import FirebaseFirestore
import Resolver

// sourcery: AutoMockable
protocol UserManaging {
    var user: CurrentValueSubject<User, Never> { get }
    func deleteAccount() -> AnyPublisher<Void, Error>
    func update(with user: User)
}

final class UserManager: UserManaging {

    // MARK: - Public Properties

    var user: CurrentValueSubject<User, Never>

    // MARK: - Private Properties

    @Injected private var analyticsManager: AnalyticsManaging
    @Injected private var authenticationManager: AuthenticationManaging
    @Injected private var database: Firestore

    private var cancellables = Cancellables()
    private var listenerBag = ListenerBag()

    init(user: User) {
        self.user = .init(user)

        listenForUser()

        self.user
            .dropFirst(2) // init, local listener
            .removeDuplicates()
            .sinkAsync {  [weak self] user in
                guard let self = self else { return }
                try await self.database.document("users/\(user.id)").updateDataEncodable(user)
            }
            .store(in: &cancellables)
    }

    func deleteAccount() -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return }
            try await self.database.document("users/\(self.user.value.id)").delete()
        }
        .flatMapLatest(withUnretained: self) { $0.authenticationManager.deleteAccount() }
        .handleEvents(withUnretained: self, receiveOutput: { try? $0.authenticationManager.signOut() })
        .eraseToAnyPublisher()
    }

    func update(with user: User) {
        self.user.send(user)
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
