import Combine
import CombineExt
import ECKit
import Factory

final class ProfileViewModel: ObservableObject {

    @Published var loading = false
    @Published var user: User!
    @Published var sharedDeepLink: DeepLink!
    
    // MARK: - Private Properties
    
    @Injected(Container.authenticationManager) private var authenticationManager
    @Injected(Container.userManager) private var userManager

    private var _delete = PassthroughRelay<Void>()
    private var _signOut = PassthroughRelay<Void>()
    
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle

    init() {
        user = userManager.user.value
        sharedDeepLink = .friendReferral(id: userManager.user.value.id)
        
        $user
            .removeDuplicates()
            .compactMap { $0 }
            .flatMapLatest(withUnretained: self) { strongSelf, user in
                strongSelf.userManager
                    .update(with: user)
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)
        
        userManager.user
            .removeDuplicates()
            .map(User?.init)
            .assign(to: &$user)

        _delete
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.userManager
                    .deleteAccount()
                    .ignoreFailure()
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .sink()
            .store(in: &cancellables)

        _signOut
            .flatMapAsync { [weak self] in try self?.authenticationManager.signOut() }
            .sink()
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        _delete.accept()
    }
    
    func signOut() {
        _signOut.accept()
    }
}
