import Foundation

struct User: Codable, Equatable, Identifiable {
    let id: String
    let email: String
    let name: String
    var friends = [String]()
    var incomingFriendRequests = [User.ID]()
    var outgoingFriendRequests = [User.ID]()
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
