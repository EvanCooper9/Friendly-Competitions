import Foundation

enum DeepLink: Equatable {
    
    private enum Constants {
        static let baseURL = URL(string: "https://friendly-competitions.app")!
        static let user = "user"
        static let competition = "competition"
    }
    
    case user(id: User.ID)
    case competition(id: Competition.ID)
    case competitionHistory(id: Competition.ID)

    init?(from url: URL) {
        let path = url.path
        if path.hasPrefix("/" + Constants.user) {
            self = .user(id: url.lastPathComponent)
            return
        } else if path.hasPrefix("/" + Constants.competition) {
            let competitionID = url.pathComponents[2]
            if path.hasSuffix("history") {
                self = .competitionHistory(id: competitionID)
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
                .appendingPathExtension(id)
        case .competition(let id):
            return Constants.baseURL
                .appendingPathComponent(Constants.competition)
                .appendingPathExtension(id)
        case .competitionHistory(let id):
            return Constants.baseURL
                .appendingPathExtension(Constants.competition)
                .appendingPathExtension(id)
                .appendingPathExtension("history")
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
        case .competitionHistory:
            return []
        }
        return [text, url.absoluteString]
    }
}
