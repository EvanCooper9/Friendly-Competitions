import Combine
import CombineExt
import ECKit
import Factory

final class CreateAccountViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var showEmailSignIn = false
    @Published private(set) var loading = false
    @Published private(set) var dismiss = false

    @Published var error: Error?

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager

    private let signInWithAppleSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        signInWithAppleSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.error = nil
                return strongSelf.authenticationManager
                    .signIn(with: .apple)
                    .isLoading { strongSelf.loading = $0 }
                    .onError { strongSelf.error = $0 }
                    .ignoreFailure()
            }
            .sink(withUnretained: self) { $0.dismiss.toggle() }
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
