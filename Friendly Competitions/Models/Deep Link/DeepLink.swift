import Foundation

enum DeepLink: Equatable {
    
    private enum Constants {
        static let baseURL = URL(string: "https://friendly-competitions.app")!
        static let user = "user"
        static let competition = "competition"
    }
    
    case user(id: User.ID)
    case competition(id: Competition.ID)
    case competitionResults(id: Competition.ID)

    init?(from url: URL) {
        let path = url.path
        if path.hasPrefix("/" + Constants.user) {
            self = .user(id: url.lastPathComponent)
            return
        } else if path.hasPrefix("/" + Constants.competition) {
            let competitionID = url.pathComponents[2]
            if path.hasSuffix("results") {
                self = .competitionResults(id: competitionID)
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
        case .competitionResults(let id):
            return Constants.baseURL
                .appendingPathComponent(Constants.competition)
                .appendingPathComponent(id)
                .appendingPathComponent("results")
        }
    }
}


extension DeepLink: Sharable {
    var itemsForSharing: [Any] {
        let text: String
        switch self {
        case .user:
            text = "Add me in Friendly Competitions!"
        case .competition:
            text = "Compete against me in Friendly Competitions!"
        case .competitionResults:
            return []
        }
        return [text, url.absoluteString]
    }
}
