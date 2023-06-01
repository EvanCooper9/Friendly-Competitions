import Combine
import CombineExt
import ECKit
import Factory

final class EmailSignInViewModel: ObservableObject {

    enum InputType {
        case signIn
        case signUp
    }

    // MARK: - Public Properties

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""

    @Published var error: Error?
    @Published private(set) var inputType = InputType.signIn
    @Published private(set) var loading = false

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager

    private let continueSubject = PassthroughSubject<InputType, Never>()
    private let forgotSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        continueSubject
            .flatMapLatest(withUnretained: self) { strongSelf, inputType in

                let publisher: AnyPublisher<Void, Error> = {
                    switch inputType {
                    case .signIn:
                        return strongSelf.authenticationManager
                            .signIn(with: .email(strongSelf.email, password: strongSelf.password))
                    case .signUp:
                        return strongSelf.authenticationManager
                            .signUp(name: strongSelf.name,
                                    email: strongSelf.email,
                                    password: strongSelf.password,
                                    passwordConfirmation: strongSelf.passwordConfirmation)
                    }
                }()

                return publisher
                    .isLoading { strongSelf.loading = $0 }
                    .handleEvents(withUnretained: self, receiveCompletion: { strongSelf, completion in
                        switch completion {
                        case .failure(let error):
                            strongSelf.error = error
                        case .finished:
                            break
                        }
                    })
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink()
            .store(in: &cancellables)

        forgotSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .sendPasswordReset(to: strongSelf.email)
                    .isLoading { strongSelf.loading = $0 }
                    .handleEvents(withUnretained: self, receiveCompletion: { strongSelf, completion in
                        switch completion {
                        case .failure(let error):
                            strongSelf.error = error
                        case .finished:
                            break
                        }
                    })
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func continueTapped() {
        continueSubject.send(inputType)
    }

    func signInTapped() {
        inputType = .signIn
    }

    func signUpTapped() {
        inputType = .signUp
    }

    func forgotTapped() {
        forgotSubject.send()
    }
}
