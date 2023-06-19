import Combine
import CombineExt
import ECKit
import Factory

final class EmailSignInViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""

    @Published var error: Error?
    @Published private(set) var inputType: EmailSignInViewInputType
    @Published private(set) var canSwitchInputType: Bool
    @Published private(set) var loading = false

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager

    private let continueSubject = PassthroughSubject<EmailSignInViewInputType, Never>()
    private let forgotSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(startingInputType: EmailSignInViewInputType, canSwitchInputType: Bool) {
        inputType = startingInputType
        self.canSwitchInputType = canSwitchInputType

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
                    .onError { strongSelf.error = $0 }
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

    func changeInputTypeTapped() {
        switch inputType {
        case .signIn:
            inputType = .signUp
        case .signUp:
            inputType = .signIn
        }
    }

    func forgotTapped() {
        forgotSubject.send()
    }
}
