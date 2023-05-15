import Combine
import CombineExt
import Factory
import Foundation

final class FetchCompetitionBackgroundJob: BackgroundJob {

    private enum CodingKeys: String, CodingKey {
        case competitionID
    }

    private let competitionID: String

    @LazyInjected(\.authenticationManager) private var authenticationManager
    @LazyInjected(\.database) private var database
    @LazyInjected(\.competitionsManager) private var competitionsManager

    func execute() -> AnyPublisher<Void, Never> {
        authenticationManager.loggedIn
            .setFailureType(to: Error.self)
            .flatMapLatest { loggedIn -> AnyPublisher<Void, Error> in
                guard loggedIn else { return .just(()) }
                return self.update()
            }
            .first()
            .catchErrorJustReturn(())
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func update() -> AnyPublisher<Void, Error> {
        // fetch fresh document from server, should get cached
        database
            .document("competitions/\(competitionID)")
            .get(as: Competition.self, source: .server)
            .mapToVoid()
            .flatMapLatest {
                // fetch fresh results from server, should get cached
                self.competitionsManager
                    .results(for: self.competitionID)
                    .mapToVoid()
            }
            .eraseToAnyPublisher()
    }
}
