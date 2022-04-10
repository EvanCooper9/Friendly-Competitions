import Combine
import CombineExt
import Resolver

final class ProfileViewModel: ObservableObject {
    
    @Published var user: User!
    
    @Injected private var authenticationManager: AnyAuthenticationManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        user = userManager.user
        
        $user
            .removeDuplicates()
            .compactMap { $0 }
            .assign(to: \.userManager.user, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        userManager.$user
            .removeDuplicates()
            .assign(to: \.user, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        userManager.deleteAccount()
    }
    
    func signOut() {
        try? authenticationManager.signOut()
    }
}
