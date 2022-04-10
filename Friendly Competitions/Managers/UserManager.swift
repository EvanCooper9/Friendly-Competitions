import Combine
import Firebase
import FirebaseCrashlytics
import FirebaseFirestore
import Resolver

class AnyUserManager: ObservableObject {
    @Published var user: User

    init(user: User) {
        self.user = user
    }

    func deleteAccount() {}
}

final class UserManager: AnyUserManager {

    @InjectedObject private var analyticsManager: AnyAnalyticsManager
    @InjectedObject private var authenticationManager: AnyAuthenticationManager
    @Injected private var database: Firestore

    private var cancellables = Set<AnyCancellable>()
    private var listenerBag = ListenerBag()

    override init(user: User) {
        super.init(user: user)
        listenForUser()

        $user
            .dropFirst(2) // 1: init, 2: local listener
            .removeDuplicates()
            .sinkAsync { [weak self] newUser in
                try await self?.update()
            }
            .store(in: &cancellables)
    }

    override func deleteAccount() {
        Task { [weak self] in
            try await self?.database.document("users/\(user.id)").delete()
            try await authenticationManager.deleteAccount()
            try await authenticationManager.signOut()
        }
    }

    // MARK: - Private Methods

    private func update() async throws {
        try await database.document("users/\(user.id)").updateDataEncodable(user)
    }

    private func listenForUser() {
        database.document("users/\(user.id)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                self.analyticsManager.set(userId: user.id)
                self.user = user
            }
            .store(in: listenerBag)
    }
}
