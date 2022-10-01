import Combine
import CombineExt
import ECKit

final class ProfileViewModel: ObservableObject {

    @Published var loading = false
    @Published var user: User!
    @Published var sharedDeepLink: DeepLink!

    private var _delete = PassthroughRelay<Void>()
    private var _signOut = PassthroughRelay<Void>()
    
    private var cancellables = Cancellables()

    init(authenticationManager: AuthenticationManaging, userManager: UserManaging) {
        user = userManager.user.value
        sharedDeepLink = .friendReferral(id: userManager.user.value.id)
        
        $user
            .removeDuplicates()
            .compactMap { $0 }
            .flatMapLatest { userManager.update(with: $0).ignoreFailure() }
            .sink()
            .store(in: &cancellables)
        
        userManager.user
            .removeDuplicates()
            .map(User?.init)
            .assign(to: &$user)

        _delete
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest {
                userManager
                    .deleteAccount()
                    .ignoreFailure()
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .sink()
            .store(in: &cancellables)

        _signOut
            .flatMapAsync { try authenticationManager.signOut() }
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
