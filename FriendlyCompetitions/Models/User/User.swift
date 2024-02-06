import Foundation

struct User: Codable, Equatable, Hashable, Identifiable {

    let id: String
    let name: String

    var appStoreID: UUID?
    var email: String?
    var friends = [String]()
    var incomingFriendRequests = [User.ID]()
    var outgoingFriendRequests = [User.ID]()
    var notificationTokens: [String]? = []
    var statistics: Medals? = .zero

    var searchable: Bool? = true
    var showRealName: Bool? = true
    var isAnonymous: Bool? = false

    var hashId: String {
        let endIndex = id.index(id.startIndex, offsetBy: 4)
        return "#" + id[..<endIndex].uppercased()
    }

    func visibility(by otherUser: User) -> Visibility {
        otherUser.id == id || friends.contains(otherUser.id) || showRealName != false ? .visible : .hidden
    }
}

extension User: Stored {
    var databasePath: String { "users/\(id)" }
}
