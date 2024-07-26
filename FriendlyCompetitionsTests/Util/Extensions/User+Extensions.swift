@testable import FriendlyCompetitions

extension User {
    func with(friends: [User.ID]) -> User {
        User(
            id: id,
            name: name,
            email: email,
            friends: friends,
            incomingFriendRequests: incomingFriendRequests,
            outgoingFriendRequests: outgoingFriendRequests,
            notificationTokens: notificationTokens,
            statistics: statistics,
            searchable: searchable,
            showRealName: showRealName,
            isAnonymous: isAnonymous,
            tags: tags
        )
    }
    
    func with(friendRequests: [User.ID]) -> User {
        User(
            id: id,
            name: name,
            email: email,
            friends: friends,
            incomingFriendRequests: friendRequests,
            outgoingFriendRequests: outgoingFriendRequests,
            notificationTokens: notificationTokens,
            statistics: statistics,
            searchable: searchable,
            showRealName: showRealName,
            isAnonymous: isAnonymous,
            tags: tags
        )
    }
}
