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

    @Published var showMoreSignInOptionsButton = true
    @Published var signInOptions: [SignInOptions] = [.apple]

    @Published var navigationPath: [WelcomeNavigationDestination] = []

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging

    private let signInSubject = PassthroughSubject<AuthenticationMethod, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        signInSubject
            .flatMapLatest(withUnretained: self) { strongSelf, authenticationMethod in
                strongSelf.authenticationManager
                    .signIn(with: authenticationMethod)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)

        try? authenticationManager.signOut()
    }

    // MARK: - Public Methods

    func signInWithAppleTapped() {
        signInSubject.send(.apple)
    }

    func signInWithEmailTapped() {
//        showEmailSignIn = true
        navigationPath = [.emailSignIn]
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
