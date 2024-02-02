import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class EmailSignInViewModel: ObservableObject {

    enum EmailSignInError: LocalizedError {
        case missingEmail

        var errorDescription: String? { localizedDescription }

        var localizedDescription: String {
            switch self {
            case .missingEmail: return L10n.EmailSignIn.missingEmail
            }
        }
    }

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

    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging

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
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                guard !strongSelf.email.isEmpty else {
                    strongSelf.error = EmailSignInError.missingEmail
                    return .never()
                }
                return .just(())
            }
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.loading = true
                return strongSelf.authenticationManager
                    .sendPasswordReset(to: strongSelf.email)
                    .handleEvents(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            strongSelf.error = error
                        case .finished:
                            break
                        }
                        strongSelf.loading = false
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
