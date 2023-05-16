import Combine
import Factory

final class FetchCompetitionResultsBackgroundJob: BackgroundJob {

    private enum CodingKeys: String, CodingKey {
        case competitionIDForResults
    }

    private let competitionIDForResults: Competition.ID

    @LazyInjected(\.authenticationManager) private var authenticationManager
    @LazyInjected(\.competitionsManager) private var competitionsManager

    func execute() -> AnyPublisher<Void, Never> {
        authenticationManager.loggedIn
            .setFailureType(to: Error.self)
            .flatMapLatest { loggedIn -> AnyPublisher<Void, Error> in
                guard loggedIn else { return .just(()) }
                return self.competitionsManager
                    .results(for: self.competitionIDForResults)
                    .mapToVoid()
                    .eraseToAnyPublisher()
            }
            .first()
            .catchErrorJustReturn(())
            .eraseToAnyPublisher()
    }
}
