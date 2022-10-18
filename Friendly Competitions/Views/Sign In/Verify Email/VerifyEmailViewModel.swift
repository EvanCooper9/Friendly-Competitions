import Combine
import CombineExt
import ECKit
import Factory

@MainActor
final class VerifyEmailViewModel: ObservableObject {

    private enum Constants {
        static let resentEmailVerification = "Re-sent email verification. Check your inbox!"
    }

    // MARK: - Private Properties
    
    @Published var user: User!
    
    @Injected(Container.appState) private var appState
    @Injected(Container.authenticationManager) private var authenticationManager
    @Injected(Container.userManager) private var userManager

    private let hud = PassthroughSubject<HUDState?, Never>()
    private let _back = PassthroughSubject<Void, Never>()
    private let _resend = PassthroughSubject<Void, Error>()
    private var cancellables = Cancellables()
    
    init() {
        user = userManager.user.value
        hud.assign(to: &appState.$hudState)

        _back
            .sinkAsync { [weak self] in try self?.authenticationManager.signOut() }
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
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
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
