import Combine
import ECKit
import Factory
import FCKit

final class AuthenticationRefreshAppService: AppService {
    
    @LazyInjected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @LazyInjected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    
    private var cancellables = Cancellables()
    
    func didReceiveRemoteNotification(with data: [AnyHashable: Any]) -> AnyPublisher<Void, Never> {
        // Attempt reauthentication before processing background tasks
        // This ensures that data uploading and other background operations can proceed
        analyticsManager.log(event: .reauthenticationTriggered)
        
        return attemptReauthenticationIfNeeded()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func attemptReauthenticationIfNeeded() -> AnyPublisher<Void, Never> {
        // Use the same logic as AuthenticationManager but adapted for background context
        authenticationManager.shouldReauthenticate()
            .catch { error -> AnyPublisher<Bool, Never> in
                self.analyticsManager.log(event: .reauthenticationFailed(error: "background_shouldReauthenticate_check_failed: \(error.localizedDescription)"))
                return .just(false)
            }
            .flatMapLatest(withUnretained: self) { strongSelf, shouldReauth in
                guard shouldReauth else {
                    strongSelf.analyticsManager.log(event: .reauthenticationSkipped(reason: "background_not_needed"))
                    return .just(())
                }
                strongSelf.analyticsManager.log(event: .reauthenticationAttempted)
                return strongSelf.authenticationManager.reauthenticate()
                    .handleEvents(
                        withUnretained: strongSelf,
                        receiveOutput: { $0.analyticsManager.log(event: .reauthenticationSuccess) },
                        receiveCompletion: { strongSelf, completion in
                            if case .failure(let error) = completion {
                                strongSelf.analyticsManager.log(event: .reauthenticationFailed(error: "background_reauthenticate_failed: \(error.localizedDescription)"))
                            }
                        }
                    )
                    .catch { error -> AnyPublisher<Void, Never> in
                        strongSelf.analyticsManager.log(event: .reauthenticationFailed(error: "background_reauthenticate_failed: \(error.localizedDescription)"))
                        return .just(())
                    }
            }
            .eraseToAnyPublisher()
    }
}