import Combine
import CombineExt
import Resolver

final class VerifyEmailViewModel: ObservableObject {

    private enum Constants {
        static let resentEmailVerification = "Re-sent email verification. Check your inbox!"
    }

    // MARK: - Private Properties
    
    @Published var user: User!

    @Injected private var appState: AppState
    @Injected private var authenticationManager: AuthenticationManaging
    @Injected private var userManager: UserManaging

    private let hud = PassthroughSubject<HUDState, Never>()

    private let _resend = PassthroughSubject<Void, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.user = userManager.user.value

        hud
            .receive(on: RunLoop.main)
            .map { $0 as HUDState? }
            .assign(to: &appState.$hudState)

        _resend
            .flatMapLatest(withUnretained: self) { $0.authenticationManager.resendEmailVerification() }
            .mapToResult()
            .sink(withUnretained: self, receiveValue: { owner, result in
                switch result {
                case .failure(let error):
                    owner.hud.send(.error(error))
                case .success:
                    owner.hud.send(.success(text: Constants.resentEmailVerification))
                }
            })
            .store(in: &cancellables)
        
        Timer
            .publish(every: 1.seconds, on: .main, in: .default)
            .autoconnect()
            .mapToValue(())
            .eraseToAnyPublisher()
            .flatMapLatest(withUnretained: self) { object in
                object.authenticationManager
                    .checkEmailVerification()
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
    
    func back() {
        try? authenticationManager.signOut()
    }
    
    func resendVerification() {
        _resend.send()
    }
}
