import Combine
import CombineExt
import ECKit
import Factory

final class ProfileViewModel: ObservableObject {

    @Published var user: User!
    @Published var confirmationRequired = false
    @Published var loading = false
    
    // MARK: - Private Properties
    
    @Injected(Container.authenticationManager) private var authenticationManager
    @Injected(Container.userManager) private var userManager

    private let deleteAccountSubject = PassthroughSubject<Void, Never>()
    private let signOutSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle

    init() {
        user = userManager.user
        
        $user
            .removeDuplicates()
            .unwrap()
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

        deleteAccountSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.userManager
                    .deleteAccount()
                    .isLoading { [weak self] in self?.loading = $0 }
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
        DeepLink.friendReferral(id: userManager.user.id).share()
    }
    
    func signOutTapped() {
        signOutSubject.send()
    }
}
