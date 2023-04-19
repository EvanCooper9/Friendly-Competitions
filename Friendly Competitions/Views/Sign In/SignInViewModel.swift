import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class SignInViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var loading = false
    @Published var signingInWithEmail = false
    @Published var isSigningUp = false
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""
    @Published private(set) var showDeveloper = false

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.authenticationManager) private var authenticationManager

    private let forgotSubject = PassthroughSubject<Void, Never>()
    private let signInSubject = PassthroughSubject<AuthenticationMethod, Never>()
    private let signUpSubject = PassthroughSubject<Void, Never>()
    private let hudSubject = PassthroughSubject<HUD, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        #if DEBUG
        showDeveloper = true
        #endif

        hudSubject
            .sink(withUnretained: self) { $0.appState.push(hud: $1) }
            .store(in: &cancellables)

        forgotSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .sendPasswordReset(to: strongSelf.email)
                    .isLoading { strongSelf.loading = $0 }
                    .mapToResult()
            }
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hudSubject.send(.error(error))
                case .success:
                    strongSelf.hudSubject.send(.success(text: L10n.SignIn.checkEmail))
                }
            })
            .store(in: &cancellables)

        signInSubject
            .flatMapLatest(withUnretained: self) { strongSelf, authenticationMethod in
                strongSelf.authenticationManager
                    .signIn(with: authenticationMethod)
                    .isLoading { strongSelf.loading = $0 }
                    .mapToResult()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hudSubject.send(.error(error))
                case .success:
                    break
                }
            })
            .store(in: &cancellables)

        signUpSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .signUp(
                        name: strongSelf.name,
                        email: strongSelf.email,
                        password: strongSelf.password,
                        passwordConfirmation: strongSelf.passwordConfirmation
                    )
                    .isLoading { strongSelf.loading = $0 }
                    .mapToResult()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hudSubject.send(.error(error))
                case .success:
                    break
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func forgot() {
        forgotSubject.send()
    }

    func submit() {
        if signingInWithEmail {
            if isSigningUp {
                signUpSubject.send()
            } else {
                signInSubject.send(.email(email, password: password))
            }
        } else {
            signInSubject.send(.apple)
        }
    }

    func showDeveloperTapped() {
        showDeveloper = true
    }
}
