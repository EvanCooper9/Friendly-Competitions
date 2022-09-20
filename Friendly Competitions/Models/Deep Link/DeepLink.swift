import Foundation

enum DeepLink: Equatable {
    
    private enum Constants {
        static let baseURL = URL(string: "https://friendly-competitions.app/")!
        static let friend = "friend/"
        static let competition = "competition/"
    }
    
    case friendReferral(id: String)
    case competitionInvite(id: String)

    init?(from url: URL) {
        if let inviteId = url.path.after(prefix: "/" + Constants.friend) {
            self = .friendReferral(id: inviteId)
        } else if let inviteId = url.path.after(prefix: "/" + Constants.competition) {
            self = .competitionInvite(id: inviteId)
        } else {
            return nil
        }
    }
    
    var url: URL {
        switch self {
        case .friendReferral(let id):
            return Constants.baseURL.appendingPathComponent(Constants.friend.appending(id))
        case.competitionInvite(let id):
            return Constants.baseURL.appendingPathComponent(Constants.competition.appending(id))
        }
    }
}


extension DeepLink: Sharable {
    var itemsForSharing: [Any] {
        let text: String
        switch self {
        case .friendReferral:
            text = "Add me in Friendly Competitions!"
        case .competitionInvite:
            text = "Compete against me in Friendly Competitions!"
        }
        return [text, url.absoluteString]
    }
}
