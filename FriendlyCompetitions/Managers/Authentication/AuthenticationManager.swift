import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol AuthenticationManaging {
    var emailVerified: AnyPublisher<Bool, Never> { get }
    var loggedIn: AnyPublisher<Bool, Never> { get }

    func signIn(with authenticationMethod: AuthenticationMethod) -> AnyPublisher<Void, Error>
    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error>
    func deleteAccount() -> AnyPublisher<Void, Error>
    func signOut() throws
    func shouldReauthenticate() -> AnyPublisher<Bool, Error>
    func reauthenticate() -> AnyPublisher<Void, Error>

    func checkEmailVerification() -> AnyPublisher<Void, Error>
    func resendEmailVerification() -> AnyPublisher<Void, Error>
    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error>
}

final class AuthenticationManager: AuthenticationManaging {

    // MARK: - Public Properties

    var emailVerified: AnyPublisher<Bool, Never> { emailVerifiedSubject.eraseToAnyPublisher() }
    var loggedIn: AnyPublisher<Bool, Never> { loggedInSubject.eraseToAnyPublisher() }

    // MARK: - Private Properties

    @Injected(\.api) private var api: API
    @Injected(\.auth) private var auth: AuthProviding
    @Injected(\.authenticationCache) private var authenticationCache: AuthenticationCache
    @Injected(\.database) private var database: Database
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.signInWithAppleProvider) private var signInWithAppleProvider: SignInWithAppleProviding

    private var emailVerifiedSubject = CurrentValueSubject<Bool, Never>(true)
    private var loggedInSubject = ReplaySubject<Bool, Never>(bufferSize: 1)

    private var userListener: AnyCancellable?
    private var createdUserSubject = ReplaySubject<User, Error>(bufferSize: 1)

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        handle(user: authenticationCache.currentUser)
        listenForAuth()
    }

    // MARK: - Public Methods

    func signIn(with authenticationMethod: AuthenticationMethod) -> AnyPublisher<Void, Error> {
        switch authenticationMethod {
        case .anonymous:
            createdUserSubject = .init(bufferSize: 1)
            return auth.signIn(with: .anonymous)
                .flatMapLatest(withUnretained: self) { $0.createUser(from: $1) }
                .mapToVoid()
                .eraseToAnyPublisher()
        case .apple:
            if let user = auth.user {
                return signInWithAppleProvider.link(with: user)
                    .flatMapLatest(withUnretained: self) { strongSelf, authUser in
                        strongSelf.database.document(authUser.databasePath)
                            .update(fields: [
                                "name": authUser.displayName?.nilIfEmpty as Any,
                                "email": authUser.email?.nilIfEmpty as Any,
                                "isAnonymous": false
                            ])
                    }
                    .eraseToAnyPublisher()
            } else {
                createdUserSubject = .init(bufferSize: 1)
                return signInWithAppleProvider.signIn()
                    .flatMapLatest(withUnretained: self) { strongSelf, authUser in
                        let document = strongSelf.database.document(authUser.databasePath)
                        return document.exists.flatMap { exists -> AnyPublisher<Void, Error> in
                            guard !exists else { return .just(()) }

                            // This is a new user, we need to create them in the database
                            return strongSelf.createUser(from: authUser)
                                .mapToVoid()
                                .eraseToAnyPublisher()
                        }
                    }
                    .mapToVoid()
                    .eraseToAnyPublisher()
            }
        case .email(let email, let password):
            return auth.signIn(with: .email(email: email, password: password))
                .mapToVoid()
                .eraseToAnyPublisher()
        }
    }

    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error> {
        guard password == passwordConfirmation else { return .error(AuthenticationError.passwordMatch) }
        if let user = auth.user {
            return user
                .link(with: .email(email: email, password: password))
                .flatMapLatest { user.set(displayName: name) }
                .flatMapLatest(withUnretained: self) { strongSelf, authUser in
                    strongSelf.database.document(authUser.databasePath)
                        .update(fields: [
                            "name": authUser.displayName?.nilIfEmpty as Any,
                            "email": authUser.email?.nilIfEmpty as Any,
                            "isAnonymous": false
                        ])
                }
                .eraseToAnyPublisher()
        } else {
            createdUserSubject = .init(bufferSize: 1)
            return auth.signUp(with: .email(email: email, password: password))
                .flatMapLatest { $0.set(displayName: name) }
                .flatMapLatest { $0.sendEmailVerification().mapToValue($0) }
                .flatMapLatest(withUnretained: self) { $0.createUser(from: $1) }
                .mapToVoid()
                .eraseToAnyPublisher()
        }
    }

    func checkEmailVerification() -> AnyPublisher<Void, Error> {
        guard let authUser = auth.user else { return .just(()) }
        return .fromAsync { try await authUser.reload() }
            .receive(on: scheduler)
            .handleEvents(withUnretained: self, receiveOutput: { $0.emailVerifiedSubject.send(authUser.isEmailVerified) })
            .eraseToAnyPublisher()
    }

    func resendEmailVerification() -> AnyPublisher<Void, Error> {
        guard let user = auth.user else { return .just(()) }
        return user.sendEmailVerification().eraseToAnyPublisher()
    }

    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        auth
            .sendPasswordReset(to: email)
            .eraseToAnyPublisher()
    }

    func deleteAccount() -> AnyPublisher<Void, Error> {
        api.call(.deleteAccount)
            .flatMapAsync { [weak self] in
                try? await self?.auth.user?.delete()
            }
            .handleEvents(withUnretained: self, receiveOutput: { try? $0.signOut() })
            .eraseToAnyPublisher()
    }

    func signOut() throws {
        try auth.signOut()
    }

    func shouldReauthenticate() -> AnyPublisher<Bool, Error> {
        guard let user = auth.user, user.hasSWA else { return .just(false) }
        return database.document("swaTokens/\(user.id)")
            .exists
            .map { !$0 }
            .eraseToAnyPublisher()
    }

    func reauthenticate() -> AnyPublisher<Void, Error> {
        signInWithAppleProvider.signIn()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Listen for sign in/out, and handle the associated user.
    /// - Set the email verification state
    /// - Register the user manager for the rest of the app
    /// - Set the logged in state
    private func listenForAuth() {
        auth.userPublisher()
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, authUser in
                if let authUser, !authUser.isAnonymous {
                    strongSelf.emailVerifiedSubject.send(authUser.isEmailVerified)
                } else {
                    strongSelf.emailVerifiedSubject.send(true)
                }
            })
            .flatMapLatest(withUnretained: self) { (strongSelf: AuthenticationManager, authUser) -> AnyPublisher<User?, Never> in
                guard let authUser else { return .just(nil) }
                let document = strongSelf.database.document(authUser.databasePath)
                return document.exists.flatMap { exists in
                    if exists {
                        return document.get(as: User.self)
                    } else {
                        /// This is a new user, the signup methods are responsible for creating the user
                        /// in the database. Listen for that update here.
                        return strongSelf.createdUserSubject.eraseToAnyPublisher()
                    }
                }
                .asOptional()
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
            }
            .sink(withUnretained: self) { $0.handle(user: $1) }
            .store(in: &cancellables)
    }

    private func handle(user: User?) {
        if let user {
            Container.shared.userManager.scope(.shared).register { [weak self] in
                let userManager = UserManager(user: user)
                self?.userListener = userManager.userPublisher.sink { self?.authenticationCache.currentUser = $0 }
                return userManager
            }
        } else {
            Container.shared.userManager.scope(.shared).reset()
        }
        authenticationCache.currentUser = user
        loggedInSubject.send(user != nil)
    }

    /// Creates a user in the database based on the auth user
    /// - Parameter authUser: the auth user
    /// - Returns: A publisher that emits the user that was created in the database
    private func createUser(from authUser: AuthUser) -> AnyPublisher<User, Error> {
        let user = User(
            id: authUser.id,
            name: authUser.displayName.emptyIfNil.ifEmpty(.anonymousName),
            email: authUser.email,
            isAnonymous: authUser.isAnonymous
        )

        return database.document(authUser.databasePath)
            .set(value: user)
            .mapToValue(user)
            .handleEvents(withUnretained: self, receiveOutput: { $0.createdUserSubject.send($1) })
            .eraseToAnyPublisher()
    }
}
