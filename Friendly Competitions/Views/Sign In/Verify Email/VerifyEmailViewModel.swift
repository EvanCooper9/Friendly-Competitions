import Combine
import CombineExt

final class VerifyEmailViewModel: ObservableObject {

    private enum Constants {
        static let resentEmailVerification = "Re-sent email verification. Check your inbox!"
    }

    // MARK: - Private Properties
    
    @Published var user: User!

    private let hud = PassthroughSubject<HUDState?, Never>()

    private let _back = PassthroughSubject<Void, Never>()
    private let _resend = PassthroughSubject<Void, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    init(appState: AppState, authenticationManager: AuthenticationManaging, userManager: UserManaging) {
        self.user = userManager.user.value

        hud
            .receive(on: RunLoop.main)
            .assign(to: &appState.$hudState)

        _back
            .sinkAsync { try authenticationManager.signOut() }
            .store(in: &cancellables)

        _resend
            .flatMapLatest(authenticationManager.resendEmailVerification)
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
            .flatMapLatest {
                authenticationManager
                    .checkEmailVerification()
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
    
    func back() {
        _back.send()
    }
    
    func resendVerification() {
        _resend.send()
    }
}
