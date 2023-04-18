import Combine
import CombineExt
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol SearchManaging {
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error>
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error>
    func searchForUsers(withIDs ids: [User.ID]) -> AnyPublisher<[User], Error>
}

final class SearchManager: SearchManaging {

    // MARK: - Private Properties

    @Injected(\.database) private var database
    @Injected(\.searchClient) private var searchClient
    @Injected(\.userManager) private var userManager
    @Injected(\.usersCache) private var usersCache

    private lazy var competitionsIndex = searchClient.index(withName: "competitions")
    private lazy var userIndex = searchClient.index(withName: "users")

    // MARK: - Public Methods

    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error> {
        competitionsIndex.search(query: name)
            .filterMany(\.isPublic)
    }

    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error> {
        userIndex.search(query: name)
            .filterMany { [weak self] user in
                guard let strongSelf = self else { return false }
                guard user.id != strongSelf.userManager.user.id else { return false }
                return user.searchable ?? false
            }
    }

    func searchForUsers(withIDs ids: [User.ID]) -> AnyPublisher<[User], Error> {
        var cached = [User]()
        var idsToFetch = [String]()
        ids.forEach { id in
            if let user = usersCache.users[id] {
                cached.append(user)
            } else {
                idsToFetch.append(id)
            }
        }

        guard idsToFetch.isNotEmpty else { return .just(cached) }
        return database.collection("users")
            .whereField("id", asArrayOf: User.self, in: idsToFetch)
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, users in
                users.forEach { strongSelf.usersCache.users[$0.id] = $0 }
            })
            .map { $0 + cached }
            .eraseToAnyPublisher()
    }
}
