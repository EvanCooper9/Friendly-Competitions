import Combine
import CombineExt
import Resolver

final class SignInViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var signingInWithEmail = false
    @Published var isSigningUp = false
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""
    
    @Injected private var appState: AppState
    @Injected private var authenticationManager: AnyAuthenticationManager
    
    private let hud = PassthroughSubject<HUDState, Never>()
    private let isLoading = PassthroughSubject<Bool, Never>()
    
    init() {
        hud
            .receive(on: RunLoop.main)
            .map { $0 as HUDState? }
            .assign(to: &appState.$hudState)
        
        isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$loading)
    }
    
    func forgot() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.authenticationManager.sendPasswordReset(to: email)
                hud.send(.success(text: "Follow the instructions in your email to reset your password"))
            } catch {
                hud.send(.error(error))
            }
        }
    }
    
    func submit() {
        if signingInWithEmail {
            if isSigningUp {
                signUp()
            } else {
                signIn(with: .email(email, password: password))
            }
        } else {
            signIn(with: .apple)
        }
    }
    
    // MARK: - Private Methods
    
    private func signIn(with provider: SignInMethod) {
        loading = true
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.authenticationManager.signIn(with: provider)
            } catch {
                hud.send(.error(error))
            }
            isLoading.send(false)
        }
    }
    
    private func signUp() {
        loading = true
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.authenticationManager.signUp(name: name, email: email, password: password, passwordConfirmation: passwordConfirmation)
            } catch {
                hud.send(.error(error))
            }
            isLoading.send(false)
        }
    }
}
