import Combine
import CombineExt
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol SearchManaging {
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error>
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error>
    func searchForUsers(withIDs userIDs: [User.ID]) -> AnyPublisher<[User], Error>
}

final class SearchManager: SearchManaging {

    // MARK: - Private Properties

    @Injected(\.database) private var database
    @Injected(\.environmentManager) private var environmentManager
    @Injected(\.searchClient) private var searchClient
    @Injected(\.userManager) private var userManager

    private lazy var competitionsIndex = searchClient.index(withName: "competitions")
    private lazy var userIndex = searchClient.index(withName: "users")

    // MARK: - Public Methods

    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error> {
        competitionsIndex.search(query: name)
            .filterMany(\.isPublic)
    }

    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error> {
        if environmentManager.environment.isDebug {
            return database.collection("users")
                .getDocuments(ofType: User.self)
                .filterMany { $0.name.contains(name) }
                .eraseToAnyPublisher()
        } else {
            return userIndex.search(query: name)
                .filterMany { [weak self] user in
                    guard let self else { return false }
                    guard user.id != self.userManager.user.id else { return false }
                    return user.searchable ?? false
                }
        }
    }

    func searchForUsers(withIDs userIDs: [User.ID]) -> AnyPublisher<[User], Error> {
        let cachedResults = database
            .collection("users")
            .whereField("id", asArrayOf: User.self, in: userIDs, source: .cache)

        return cachedResults
            .flatMapLatest(withUnretained: self) { strongSelf, cachedResults -> AnyPublisher<[User], Error> in
                let remaining = userIDs.subtracting(cachedResults.map(\.id))
                guard remaining.isNotEmpty else { return .just(cachedResults) }
                return strongSelf.database
                    .collection("users")
                    .whereField("id", asArrayOf: User.self, in: userIDs, source: .server)
                    .map { $0 + cachedResults }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}