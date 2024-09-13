import Foundation

struct User: Codable, Equatable, Hashable, Identifiable {

    let id: String
    let name: String
    let email: String?
    let friends: [String]
    let incomingFriendRequests: [User.ID]
    let outgoingFriendRequests: [User.ID]
    let notificationTokens: [String]
    let statistics: Medals
    var searchable: Bool
    var showRealName: Bool
    let isAnonymous: Bool
    let tags: [Tag]
    let profilePicturePath: String?

    var hashId: String {
        let endIndex = id.index(id.startIndex, offsetBy: 4)
        return "#" + id[..<endIndex].uppercased()
    }

    func visibility(by otherUser: User) -> Visibility {
        otherUser.id == id || friends.contains(otherUser.id) || showRealName != false ? .visible : .hidden
    }

    internal init(
        id: String,
        name: String,
        email: String?,
        friends: [String] = [],
        incomingFriendRequests: [User.ID] = [],
        outgoingFriendRequests: [User.ID] = [],
        notificationTokens: [String] = [],
        statistics: User.Medals = .zero,
        searchable: Bool = true,
        showRealName: Bool = true,
        isAnonymous: Bool = false,
        tags: [User.Tag] = [],
        profilePicturePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.friends = friends
        self.incomingFriendRequests = incomingFriendRequests
        self.outgoingFriendRequests = outgoingFriendRequests
        self.notificationTokens = notificationTokens
        self.statistics = statistics
        self.searchable = searchable
        self.showRealName = showRealName
        self.isAnonymous = isAnonymous
        self.tags = tags
        self.profilePicturePath = profilePicturePath
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.friends = (try container.decodeIfPresent([String].self, forKey: .friends)) ?? []
        self.incomingFriendRequests = (try container.decodeIfPresent([User.ID].self, forKey: .incomingFriendRequests)) ?? []
        self.outgoingFriendRequests = (try container.decodeIfPresent([User.ID].self, forKey: .outgoingFriendRequests)) ?? []
        self.notificationTokens = (try container.decodeIfPresent([String].self, forKey: .notificationTokens)) ?? []
        self.statistics = (try container.decodeIfPresent(User.Medals.self, forKey: .statistics)) ?? .zero
        self.searchable = (try container.decodeIfPresent(Bool.self, forKey: .searchable)) ?? true
        self.showRealName = (try container.decodeIfPresent(Bool.self, forKey: .showRealName)) ?? true
        self.isAnonymous = (try container.decodeIfPresent(Bool.self, forKey: .isAnonymous)) ?? false
        self.tags = (try container.decodeIfPresent([User.Tag].self, forKey: .tags)) ?? []
        self.profilePicturePath = try? container.decodeIfPresent(String.self, forKey: .profilePicturePath)
    }
}

extension User: Stored {
    var databasePath: String { "users/\(id)" }
}
