import Combine
import CombineExt
import ECKit
import Factory

final class ProfileViewModel: ObservableObject {

    @Published var user: User!
    @Published var confirmationRequired = false
    @Published var loading = false
    @Published var showHideNameLearnMore = false

    @Published var showCreateAccount = false
    @Published var isAnonymousAccount = false

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager
    @Injected(\.featureFlagManager) private var featureFlagManager
    @Injected(\.userManager) private var userManager

    private let deleteAccountSubject = PassthroughSubject<Void, Never>()
    private let signOutSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        $user
            .unwrap()
            .removeDuplicates()
            .dropFirst()
            .flatMapLatest(withUnretained: self) { strongSelf, user in
                strongSelf.userManager
                    .update(with: user)
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)

        $user
            .unwrap()
            .map { $0.isAnonymous == true }
            .assign(to: &$isAnonymousAccount)

        userManager.userPublisher
            .removeDuplicates()
            .map(User?.init)
            .assign(to: &$user)

        deleteAccountSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .shouldReauthenticate()
                    .flatMapLatest { shouldReauthenticate -> AnyPublisher<Void, Error> in
                        guard shouldReauthenticate else { return .just(()) }
                        return strongSelf.authenticationManager.reauthenticate()
                    }
                    .flatMapLatest { strongSelf.authenticationManager.deleteAccount() }
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)

        signOutSubject
            .flatMapAsync { [weak self] in try self?.authenticationManager.signOut() }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func confirmTapped() {
        deleteAccountSubject.send()
    }

    func deleteAccountTapped() {
        confirmationRequired.toggle()
    }

    func shareInviteLinkTapped() {
        DeepLink.user(id: userManager.user.id).share()
    }

    func signUpTapped() {
        showCreateAccount.toggle()
    }

    func signOutTapped() {
        signOutSubject.send()
    }

    func hideNameLearnMoreTapped() {
        showHideNameLearnMore.toggle()
    }
}
