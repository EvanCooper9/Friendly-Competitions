import Foundation

enum DeepLink {
    case friendReferral(id: String)
    case competitionInvite(id: String)

    init?(from url: URL) {
        if let inviteId = url.path.string(after: "/friend/") {
            self = .friendReferral(id: inviteId)
        } else if let inviteId = url.path.string(after: "/competition/") {
            self = .competitionInvite(id: inviteId)
        } else {
            return nil
        }
    }
}

private extension String {
    func string(after prefix: String) -> String? {
        guard starts(with: prefix) else { return nil }
        return String(prefix.dropFirst(prefix.count))
    }
}
