import Foundation

enum DeepLink {
    case friendReferral(id: String)
    case competitionInvite(id: String)

    init?(from url: URL) {
        if let inviteId = url.path.after(prefix: "/friend/") {
            self = .friendReferral(id: inviteId)
        } else if let inviteId = url.path.after(prefix: "/competition/") {
            self = .competitionInvite(id: inviteId)
        } else {
            return nil
        }
    }
}
