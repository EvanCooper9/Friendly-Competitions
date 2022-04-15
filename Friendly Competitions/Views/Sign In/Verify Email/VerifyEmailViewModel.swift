import Combine
import CombineExt
import Resolver

final class VerifyEmailViewModel: ObservableObject {
    
    @Published var user: User!

    @Injected private var authenticationManager: AnyAuthenticationManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.user = userManager.user
        userManager.$user
            .assign(to: \.user, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        poll()
    }
    
    func back() {
        try? authenticationManager.signOut()
    }
    
    func resendVerification() {
        Task {
            try await authenticationManager.resendEmailVerification()
        }
    }
    
    private func poll() {
        Task.detached(priority: .low) { [weak self] in
            guard let self = self else { return }
            guard !self.authenticationManager.emailVerified else { return }
            try await self.authenticationManager.checkEmailVerification()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            self.poll()
        }
    }
}
