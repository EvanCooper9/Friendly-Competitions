import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class WelcomeViewModel: ObservableObject {

    enum SignInOptions: String, Identifiable {
        case anonymous
        case apple
        case email

        var id: String { rawValue }
    }

    // MARK: - Public Properties

    let appNape = Bundle.main.displayName
    @Published private(set) var loading = false
    @Published var showAnonymousSignInConfirmation = false
    @Published var showEmailSignIn = false

    @Published var showMoreSignInOptionsButton = true
    @Published var signInOptions: [SignInOptions] = [.apple]

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager

    private let signInSubject = PassthroughSubject<AuthenticationMethod, Error>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        signInSubject
            .flatMapLatest(withUnretained: self) { strongSelf, authenticationMethod in
                strongSelf.authenticationManager
                    .signIn(with: authenticationMethod)
                    .isLoading { strongSelf.loading = $0 }
            }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func signInWithAppleTapped() {
        signInSubject.send(.apple)
    }

    func signInWithEmailTapped() {
        showEmailSignIn = true
    }

    func signInAnonymouslyTapped() {
        showAnonymousSignInConfirmation = true
    }

    func confirmAnonymousSignIn() {
        signInSubject.send(.anonymous)
    }

    func moreOptionsTapped() {
        signInOptions = [.apple, .email, .anonymous]
        showMoreSignInOptionsButton = false
    }
}
