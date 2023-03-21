import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class VerifyEmailViewModel: ObservableObject {

    private enum Constants {
        static let resentEmailVerification = "Re-sent email verification. Check your inbox!"
    }

    // MARK: - Public Properties

    @Published var user: User!

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.authenticationManager) private var authenticationManager
    @Injected(\.userManager) private var userManager

    private let hudSubject = PassthroughSubject<HUD, Never>()
    private let backSubject = PassthroughSubject<Void, Never>()
    private let resendSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    init() {
        user = userManager.user

        hudSubject
            .sink(withUnretained: self) { $0.appState.push(hud: $1) }
            .store(in: &cancellables)

        backSubject
            .sink(withUnretained: self) { try? $0.authenticationManager.signOut() }
            .store(in: &cancellables)

        resendSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .resendEmailVerification()
                    .mapToResult()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self) { strongSelf, result in
                switch result {
                case .failure(let error):
                    strongSelf.hudSubject.send(.error(error))
                case .success:
                    strongSelf.hudSubject.send(.success(text: Constants.resentEmailVerification))
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
