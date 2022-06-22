import Combine
import CombineExt
import Resolver

final class ProfileViewModel: ObservableObject {

    @Published var loading = false
    @Published var user: User!
    @Published var sharedDeepLink: DeepLink!
    
    @Injected private var authenticationManager: AuthenticationManaging
    @Injected private var userManager: UserManaging

    private var _delete = PassthroughRelay<Void>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        user = userManager.user.value
        sharedDeepLink = .friendReferral(id: userManager.user.value.id)
        
        $user
            .removeDuplicates()
            .compactMap { $0 }
            .sink(withUnretained: self, receiveValue: { $0.userManager.update(with: $1) })
            .store(in: &cancellables)
        
        userManager.user
            .removeDuplicates()
            .map { $0 as User? }
            .assign(to: &$user)

        _delete
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = true })
            .flatMapLatest(withUnretained: self) { owner in
                owner.userManager
                    .deleteAccount()
                    .ignoreFailure()
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .sink()
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        _delete.accept()
    }
    
    func signOut() {
        try? authenticationManager.signOut()
    }
}
