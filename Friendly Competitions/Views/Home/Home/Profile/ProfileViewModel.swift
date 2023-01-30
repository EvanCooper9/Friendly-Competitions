import Combine
import CombineExt
import ECKit
import Factory

final class ProfileViewModel: ObservableObject {

    @Published var user: User!
    @Published var premium: Premium?
    @Published var confirmationRequired = false
    @Published var loading = false
    @Published var editing = false
    
    @Published var nameForEdititng = ""
    @Published var emailForEditing = ""
    
    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    @Injected(Container.authenticationManager) private var authenticationManager
    @Injected(Container.premiumManager) private var premiumManager
    @Injected(Container.userManager) private var userManager

    private let saveEditsSubject = PassthroughSubject<Void, Never>()
    private let deleteAccountSubject = PassthroughSubject<Void, Never>()
    private let signOutSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle

    init() {
        user = userManager.user
        nameForEdititng = userManager.user.name
        emailForEditing = userManager.user.email
        
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
        
        saveEditsSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                var user = strongSelf.userManager.user
                user.name = strongSelf.nameForEdititng
                user.email = strongSelf.emailForEditing
                return strongSelf.userManager
                    .update(with: user)
                    .isLoading { strongSelf.loading = $0 }
                    .catch { error -> AnyPublisher<Void, Never> in
                        strongSelf.appState.push(hud: .error(error))
                        return .just(())
                    }
                    .eraseToAnyPublisher()
            }
            .sink(withUnretained: self) { $0.editing = false }
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
    
    func signOutTapped() {
        signOutSubject.send()
    }
    
    func editTapped() {
        editing.toggle()
    }
    
    func cancelTapped() {
        editing.toggle()
        nameForEdititng = user.name
        emailForEditing = user.email
    }
    
    func saveTapped() {
        saveEditsSubject.send()
    }
}
