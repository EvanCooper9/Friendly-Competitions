import Foundation

final class User: Codable, Identifiable {
    let id: String
    let email: String
    var name: String
    var friends: [String]
    let incomingFriendRequests: [String]
    let outgoingFriendRequests: [String]
    var notificationTokens: [String]

    var tempActivitySummary: ActivitySummary? = nil

    init(id: String, email: String, name: String, friends: [String] = [], incomingFriendRequests: [String] = [], outgoingFriendRequests: [String] = [], notificationTokens: [String] = []) {
        self.id = id
        self.email = email
        self.name = name
        self.friends = friends
        self.incomingFriendRequests = incomingFriendRequests
        self.outgoingFriendRequests = outgoingFriendRequests
        self.notificationTokens = notificationTokens
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

extension User: ObservableObject {}
