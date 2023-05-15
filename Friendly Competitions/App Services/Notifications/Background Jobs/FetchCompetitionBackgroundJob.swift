import Combine
import CombineExt
import Factory

final class FetchCompetitionBackgroundJob: BackgroundJob {

    private enum CodingKeys: String, CodingKey {
        case competitionID
    }

    let competitionID: String

    @LazyInjected(\.authenticationManager) private var authenticationManager
    @LazyInjected(\.database) private var database
    @LazyInjected(\.competitionsManager) private var competitionsManager

    func execute() -> AnyPublisher<Void, Never> {
        authenticationManager.loggedIn
            .first()
            .flatMapLatest(withUnretained: self) { strongSelf, loggedIn -> AnyPublisher<Void, Never> in
                guard loggedIn else { return .just(()) }
                return strongSelf.update()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func update() -> AnyPublisher<Void, Never> {
        // fetch fresh document from server, should get cached
        database
            .document("competitions/\(competitionID)")
            .get(as: Competition.self, source: .server)
            .mapToVoid()
            .flatMapLatest(withUnretained: self) { strongSelf in
                // fetch fresh results from server, should get cached
                strongSelf.competitionsManager
                    .results(for: strongSelf.competitionID)
                    .mapToVoid()
            }
            .catchErrorJustReturn(())
            .eraseToAnyPublisher()
    }
}
