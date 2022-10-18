import Combine
import CombineExt
import ECKit
import Factory

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

    private let _forgot = PassthroughSubject<Void, Never>()
    private let _signIn = PassthroughSubject<SignInMethod, Never>()
    private let _signUp = PassthroughSubject<Void, Never>()
    private let hud = PassthroughSubject<HUDState?, Never>()
    private let isLoading = PassthroughSubject<Bool, Never>()

    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        hud.assign(to: &appState.$hudState)
        isLoading.assign(to: &$loading)

        _forgot
            .setFailureType(to: Error.self)
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager.sendPasswordReset(to: strongSelf.email)
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
                case .success:
                    strongSelf.hud.send(.success(text: Constants.checkEmail))
                }
            })
            .store(in: &cancellables)

        _signIn
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { strongSelf, signInMethod in
                strongSelf.authenticationManager
                    .signIn(with: signInMethod)
                    .isLoading { [weak self] in self?.loading = $0  }
                    .eraseToAnyPublisher()
            }
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
                case .success:
                    break
                }
            })
            .store(in: &cancellables)

        _signUp
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .signUp(
                        name: strongSelf.name,
                        email: strongSelf.email,
                        password: strongSelf.password,
                        passwordConfirmation: strongSelf.passwordConfirmation
                    )
                    .isLoading { [weak self] in self?.loading = $0 }
                    .eraseToAnyPublisher()
            }
            .mapToResult()
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
        _forgot.send()
    }
    
    func submit() {
        if signingInWithEmail {
            if isSigningUp {
                _signUp.send()
            } else {
                _signIn.send(.email(email, password: password))
            }
        } else {
            _signIn.send(.apple)
        }
    }
}
