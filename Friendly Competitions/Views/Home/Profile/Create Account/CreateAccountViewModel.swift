import Combine
import CombineExt
import ECKit
import Factory

final class CreateAccountViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var loading = false
    @Published var showEmailSignIn = false

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager

    private let signInWithAppleSubject = PassthroughSubject<Void, Error>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        signInWithAppleSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .signIn(with: .apple)
                    .isLoading { strongSelf.loading = $0}
            }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func signInWithAppleTapped() {
        signInWithAppleSubject.send(())
    }

    func signInWithEmailTapped() {
        showEmailSignIn = true
    }
}
