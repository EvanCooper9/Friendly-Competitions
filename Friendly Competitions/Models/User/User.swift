import Foundation

enum Visibility {
    case visible
    case hidden
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    var friends = [String]()
    var incomingFriendRequests = [String]()
    var outgoingFriendRequests = [String]()
    var notificationTokens: [String]? = []
    var statistics: Statistics? = .zero

    var searchable: Bool? = true
    var showRealName: Bool? = true

    var hashId: String {
        let endIndex = id.index(id.startIndex, offsetBy: 4)
        return "#" + id[..<endIndex].uppercased()
    }
    
    func visibility(by otherUser: User) -> Visibility {
        otherUser.id == id || friends.contains(otherUser.id) || showRealName != false ? .visible : .hidden
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
