import Combine
import CombineExt
import ECKit

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

    private let _forgot = PassthroughSubject<Void, Never>()
    private let _signIn = PassthroughSubject<SignInMethod, Never>()
    private let _signUp = PassthroughSubject<Void, Never>()
    private let hud = PassthroughSubject<HUDState?, Never>()
    private let isLoading = PassthroughSubject<Bool, Never>()

    private var cancellables = Cancellables()
    
    init(appState: AppState, authenticationManager: AuthenticationManaging) {
        hud
            .receive(on: RunLoop.main)
            .assign(to: &appState.$hudState)
        
        isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$loading)

        _forgot
            .setFailureType(to: Error.self)
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest(withUnretained: self) { object in
                authenticationManager.sendPasswordReset(to: object.email)
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { object, result in
                switch result {
                case .failure(let error):
                    object.hud.send(.error(error))
                case .success:
                    object.hud.send(.success(text: Constants.checkEmail))
                }
            })
            .store(in: &cancellables)

        _signIn
            .setFailureType(to: Error.self)
            .handleEvents(withUnretained: self, receiveOutput: { object, _ in object.loading = true })
            .flatMapLatest { signInMethod in
                authenticationManager.signIn(with: signInMethod)
            }
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { object, result in
                object.loading = false
                switch result {
                case .failure(let error):
                    object.hud.send(.error(error))
                case .success:
                    break
                }
            })
            .store(in: &cancellables)

        _signUp
            .setFailureType(to: Error.self)
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest(withUnretained: self) { object in
                authenticationManager.signUp(
                    name: object.name,
                    email: object.email,
                    password: object.password,
                    passwordConfirmation: object.passwordConfirmation
                )
            }
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { object, result in
                object.loading = false
                switch result {
                case .failure(let error):
                    object.hud.send(.error(error))
                case .success:
                    break
                }
            })
            .store(in: &cancellables)
    }
    
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
