import Combine
import CombineExt
import ECKit
import Factory
import Foundation

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
    private let backSubject = PassthroughSubject<Void, Never>()
    private let resendSubject = PassthroughSubject<Void, Error>()
    private var cancellables = Cancellables()
    
    init() {
        user = userManager.user.value
        hud.assign(to: &appState.$hudState)

        backSubject
            .sinkAsync { [weak self] in try self?.authenticationManager.signOut() }
            .store(in: &cancellables)

        resendSubject
            .flatMapLatest(authenticationManager.resendEmailVerification)
            .mapToResult()
            .sink(withUnretained: self) { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hud.send(.error(error))
                case .success:
                    strongSelf.hud.send(.success(text: Constants.resentEmailVerification))
                }
            }
            .store(in: &cancellables)
        
        Timer
            .publish(every: 5.seconds, on: .main, in: .default)
            .autoconnect()
            .mapToValue(())
            .eraseToAnyPublisher()
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .checkEmailVerification()
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink()
            .store(in: &cancellables)
    }
    
    func back() {
        backSubject.send()
    }
    
    func resendVerification() {
        resendSubject.send()
    }
}
