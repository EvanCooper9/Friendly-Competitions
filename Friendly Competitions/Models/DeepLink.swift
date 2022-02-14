import Foundation

enum DeepLink {
    case friendReferral(id: String)

    init?(from url: URL) {
        print(url.path)
        if let inviteId = url.path.string(after: "/invite/") {
            self = .friendReferral(id: inviteId)
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
