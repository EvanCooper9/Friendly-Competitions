import Combine
import ECKit
import Factory
import Foundation

enum DeepLink: Equatable {

    private enum Constants {
        static let baseURL = URL(string: "https://friendly-competitions.app")!
        static let user = "user"
        static let competition = "competition"
    }

    case user(id: User.ID)
    case competition(id: Competition.ID)
    case competitionResult(id: Competition.ID, resultID: CompetitionResult.ID?)

    init?(from url: URL) {
        let path = url.path
        if path.hasPrefix("/" + Constants.user) {
            self = .user(id: url.lastPathComponent)
            return
        } else if path.hasPrefix("/" + Constants.competition) {
            let competitionID = url.pathComponents[2]
            if path.contains("results") {
                let resultID: String? = {
                    let pathComponents = url.pathComponents
                    guard pathComponents.count == 3 else { return nil }
                    return pathComponents.last
                }()
                self = .competitionResult(id: competitionID, resultID: resultID)
                return
            } else {
                self = .competition(id: competitionID)
                return
            }
        }
        return nil
    }

    var url: URL {
        switch self {
        case .user(let id):
            return Constants.baseURL
                .appendingPathComponent(Constants.user)
                .appendingPathComponent(id)
        case .competition(let id):
            return Constants.baseURL
                .appendingPathComponent(Constants.competition)
                .appendingPathComponent(id)
        case .competitionResult(let competitionID, let resultID):
            let competitionURL = Constants.baseURL
                .appendingPathComponent(Constants.competition)
                .appendingPathComponent(competitionID)

            if let resultID {
                return competitionURL
                    .appendingPathComponent("results")
                    .appendingPathComponent(resultID)
            }
            return competitionURL
        }
    }

    var navigationDestination: AnyPublisher<NavigationDestination?, Never> {

        let database = Container.shared.database.resolve()
        let friendsManager = Container.shared.friendsManager.resolve()
        let competitionsManager = Container.shared.competitionsManager.resolve()

        switch self {
        case .user(let id):
            return friendsManager.user(withId: id)
                .map { .user($0) }
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        case .competition(let id):
            return competitionsManager.search(byID: id)
                .map { .competition($0, nil) }
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        case .competitionResult(let competitionID, let resultID):
            let competition = database
                .document("competitions/\(competitionID)")
                .get(as: Competition.self)
                .print("competition")

            var result: AnyPublisher<CompetitionResult?, Error> = .just(nil)
            if let resultID {
                result = database
                    .document("competitions/\(competitionID)/results/\(resultID)")
                    .get(as: CompetitionResult.self)
                    .map { $0 as CompetitionResult? }
                    .eraseToAnyPublisher()
            }

            return Publishers.CombineLatest(competition, result)
                .map { .competition($0, $1) }
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        }
    }
}

extension DeepLink: Sharable {
    var itemsForSharing: [Any] {
        [url]
    }
}
