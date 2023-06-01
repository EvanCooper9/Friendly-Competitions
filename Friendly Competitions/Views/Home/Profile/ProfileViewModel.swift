import Combine
import CombineExt
import ECKit
import Factory

final class ProfileViewModel: ObservableObject {

    @Published var user: User!
    @Published private(set) var premium: Premium?
    @Published var confirmationRequired = false
    @Published var loading = false
    @Published var showHideNameLearnMore = false

    @Published var showCreateAccount = false
    var isAnonymousAccount: Bool {
        user.isAnonymous == true
    }

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager
    @Injected(\.premiumManager) private var premiumManager
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

        userManager.userPublisher
            .removeDuplicates()
            .map(User?.init)
            .assign(to: &$user)

        premiumManager.premium.assign(to: &$premium)

        deleteAccountSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.userManager
                    .deleteAccount()
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

    func manageSubscriptionTapped() {
        premiumManager.manageSubscription()
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
