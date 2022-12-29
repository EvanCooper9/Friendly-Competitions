import Combine
import CombineExt
import ECKit
import Factory
import Foundation

@MainActor
final class SignInViewModel: ObservableObject {

    private enum Constants {
        static let checkEmail = "Follow the instructions in your email to reset your password"
    }

    // MARK: - Public Properties
    
    @Published var loading = false
    @Published var signingInWithEmail = false
    @Published var isSigningUp = false
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""

    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    @Injected(Container.authenticationManager) private var authenticationManager

    private let forgotSubject = PassthroughSubject<Void, Never>()
    private let signInSubject = PassthroughSubject<SignInMethod, Never>()
    private let signUpSubject = PassthroughSubject<Void, Never>()
    private let hud = PassthroughSubject<HUDState?, Never>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        hud.assign(to: &appState.$hudState)

        forgotSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .sendPasswordReset(to: strongSelf.email)
                    .isLoading { [weak self] in self?.loading = $0 }
                    .mapToResult()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
                case .success:
                    strongSelf.hud.send(.success(text: Constants.checkEmail))
                }
            })
            .store(in: &cancellables)

        signInSubject
            .flatMapLatest(withUnretained: self) { strongSelf, signInMethod in
                strongSelf.authenticationManager
                    .signIn(with: signInMethod)
                    .isLoading { [weak self] in self?.loading = $0  }
                    .mapToResult()
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
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
                    .isLoading { [weak self] in self?.loading = $0 }
                    .mapToResult()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
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
}
